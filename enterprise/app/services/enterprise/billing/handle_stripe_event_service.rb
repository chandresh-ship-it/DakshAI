class Enterprise::Billing::HandleStripeEventService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  CAPTAIN_CLOUD_PLAN_LIMITS = 'CAPTAIN_CLOUD_PLAN_LIMITS'.freeze

  def perform(event:)
    @event = event

    ProcessedWebhookEvent.transaction do
      if ProcessedWebhookEvent.exists?(stripe_event_id: @event.id)
        Rails.logger.warn("Stripe event #{@event.id} already processed. Skipping.")
        return true
      end

      ProcessedWebhookEvent.create!(
        stripe_event_id: @event.id,
        event_type: @event.type,
        processed_at: Time.current
      )

      case @event.type
      when 'customer.subscription.created', 'customer.subscription.updated'
        process_subscription_updated
      when 'customer.subscription.deleted'
        process_subscription_deleted
      when 'invoice.payment_succeeded'
        process_invoice_payment_succeeded
      else
        Rails.logger.debug { "Unhandled event type: #{@event.type}" }
      end
    end
  end

  private

  def process_subscription_updated
    if marketplace_subscription?
      process_marketplace_subscription_updated
    else
      process_platform_subscription_updated
    end
  end

  def process_marketplace_subscription_updated
    client_account_id = subscription.metadata['client_account_id']
    client_account = Account.find_by(id: client_account_id)
    return if client_account.blank?

    plan_price_id = subscription.metadata['marketplace_plan_price_id']
    plan_price = MarketplacePlanPrice.find_by(id: plan_price_id)
    return if plan_price.blank?

    sub_record = Subscription.find_or_initialize_by(account: client_account)
    sub_record.update!(
      stripe_customer_id: subscription.customer,
      stripe_subscription_id: subscription.id,
      status: subscription.status,
      relationship_type: 'marketplace',
      connected_account_id: subscription.metadata['connected_account_id'],
      application_fee_amount: plan_price.platform_fee_amount,
      stripe_price_id: subscription['plan']['id'],
      stripe_product_id: subscription['plan']['product'],
      plan_name: 'Workspace Subscription',
      subscribed_quantity: subscription['quantity'],
      current_period_start: Time.zone.at(subscription['current_period_start']),
      current_period_end: Time.zone.at(subscription['current_period_end'])
    )

    client_account.update(
      custom_attributes: (client_account.custom_attributes || {}).merge(
        'stripe_customer_id' => subscription.customer,
        'stripe_subscription_id' => subscription.id,
        'subscription_status' => subscription.status,
        'plan_name' => 'Marketplace Plan',
        'subscribed_quantity' => subscription['quantity'],
        'subscription_ends_on' => Time.zone.at(subscription['current_period_end'])
      )
    )

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: client_account).perform
  end

  def process_platform_subscription_updated
    plan = resolve_plan
    return if plan.blank? || account.blank?

    previous_usage = capture_previous_usage
    update_account_attributes(subscription, plan)

    sub_record = Subscription.find_or_initialize_by(account: account)
    sub_record.update!(
      stripe_customer_id: subscription.customer,
      stripe_subscription_id: subscription.id,
      status: subscription.status,
      relationship_type: 'platform',
      stripe_price_id: subscription['plan']['id'],
      stripe_product_id: subscription['plan']['product'],
      plan_name: plan['name'],
      subscribed_quantity: subscription['quantity'],
      current_period_start: Time.zone.at(subscription['current_period_start']),
      current_period_end: Time.zone.at(subscription['current_period_end'])
    )

    if account.is_reseller?
      if %w[past_due unpaid].include?(subscription.status)
        sub_account_ids = account.sub_accounts.pluck(:id)
        Subscription.where(account_id: sub_account_ids).update_all(grace_period_ends_at: 7.days.from_now)
      elsif subscription.status == 'active'
        sub_account_ids = account.sub_accounts.pluck(:id)
        Subscription.where(account_id: sub_account_ids).update_all(grace_period_ends_at: nil)
      end
    end

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: account).perform

    if billing_period_renewed?
      ActiveRecord::Base.transaction do
        handle_subscription_credits(plan, previous_usage)
        account.reset_response_usage
      end
    elsif plan_changed?
      handle_plan_change_credits(plan, previous_usage)
    end
  end

  def process_subscription_deleted
    if marketplace_subscription?
      process_marketplace_subscription_deleted
    else
      process_platform_subscription_deleted
    end
  end

  def process_marketplace_subscription_deleted
    client_account_id = subscription.metadata['client_account_id']
    client_account = Account.find_by(id: client_account_id)
    return if client_account.blank?

    sub_record = Subscription.find_by(stripe_subscription_id: subscription.id)
    sub_record&.update!(status: 'canceled')

    client_account.update(
      custom_attributes: (client_account.custom_attributes || {}).merge(
        'subscription_status' => 'canceled'
      )
    )
  end

  def process_platform_subscription_deleted
    return if account.blank?

    previous_monthly_credits = current_plan_credits[:responses]
    return unless Enterprise::Billing::CreateStripeCustomerService.new(account: account).perform

    sub_record = Subscription.find_by(stripe_subscription_id: subscription.id)
    sub_record&.update!(status: 'canceled')

    account.with_lock do
      previous_usage = { responses: account.custom_attributes['captain_responses_usage'].to_i, monthly: previous_monthly_credits }
      adjust_captain_credits(previous_usage, new_plan_credits: 0)
      account.reset_response_usage
    end
  end

  def process_invoice_payment_succeeded
    invoice = @event.data.object
    return if invoice.subscription.blank?

    stripe_subscription = Stripe::Subscription.retrieve(invoice.subscription)
    return if stripe_subscription.blank?
    return unless stripe_subscription.metadata['relationship_type'] == 'marketplace'

    connected_account_id = stripe_subscription.metadata['connected_account_id']
    connected_account = ConnectedAccount.find_by(id: connected_account_id)
    return if connected_account.blank?
    return unless connected_account.charge_routing == 'separate_charge_transfer'
    return if invoice.charge.blank?

    agency_price = stripe_subscription.metadata['agency_price'].to_f
    currency = invoice.currency

    transfers = Stripe::Transfer.list(source_transaction: invoice.charge)
    return if transfers.data.present?

    Stripe::Transfer.create({
                              amount: (agency_price * 100).to_i,
                              currency: currency.downcase,
                              destination: connected_account.stripe_account_id,
                              source_transaction: invoice.charge,
                              description: "Transfer to reseller for client invoice #{invoice.id}"
                            })
  rescue Stripe::StripeError => e
    Rails.logger.error("Failed to transfer funds to reseller for invoice #{invoice.id}: #{e.message}")
  end

  def capture_previous_usage
    { responses: account.custom_attributes['captain_responses_usage'].to_i, monthly: current_plan_credits[:responses] }
  end

  def current_plan_credits
    plan_name = account.custom_attributes['plan_name']
    plan_credits = get_plan_credits(plan_name) if plan_name.present?
    plan_credits || { responses: 0, documents: 0 }
  end

  def update_account_attributes(subscription, plan)
    account.update(
      custom_attributes: account.custom_attributes.merge(
        'stripe_customer_id' => subscription.customer,
        'stripe_price_id' => subscription['plan']['id'],
        'stripe_product_id' => subscription['plan']['product'],
        'plan_name' => plan['name'],
        'subscribed_quantity' => subscription['quantity'],
        'subscription_status' => subscription['status'],
        'subscription_ends_on' => Time.zone.at(subscription['current_period_end'])
      )
    )
  end

  def handle_subscription_credits(plan, previous_usage)
    adjust_captain_credits(previous_usage, new_plan_credits: get_plan_credits(plan['name'])[:responses])
  end

  def adjust_captain_credits(previous_usage, new_plan_credits:)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    consumed_topup_credits = [previous_usage[:responses] - previous_usage[:monthly], 0].max
    updated_credits = [current_credits - consumed_topup_credits - previous_usage[:monthly] + new_plan_credits, 0].max

    Rails.logger.info("Updating captain credits for account #{account.id}: #{current_credits} -> #{updated_credits}")
    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def handle_plan_change_credits(new_plan, previous_usage)
    current_limits = account.limits || {}
    current_credits = current_limits['captain_responses'].to_i

    previous_plan_credits = previous_usage[:monthly]
    new_plan_credits = get_plan_credits(new_plan['name'])[:responses]

    updated_credits = current_credits - previous_plan_credits + new_plan_credits

    account.update!(limits: current_limits.merge('captain_responses' => updated_credits))
  end

  def get_plan_credits(plan_name)
    config = InstallationConfig.find_by(name: CAPTAIN_CLOUD_PLAN_LIMITS).value
    config = JSON.parse(config) if config.is_a?(String)
    config[plan_name.downcase]&.symbolize_keys
  end

  def subscription
    @subscription ||= @event.data.object
  end

  def previous_attributes
    @previous_attributes ||= JSON.parse((@event.data.previous_attributes || {}).to_json)
  end

  def plan_changed?
    return false if previous_attributes['plan'].blank?

    previous_plan_id = previous_attributes.dig('plan', 'id')
    current_plan_id = subscription['plan']['id']

    previous_plan_id != current_plan_id
  end

  def billing_period_renewed?
    return false if previous_attributes['current_period_start'].blank?

    previous_attributes['current_period_start'] != subscription['current_period_start']
  end

  def account
    @account ||= Account.where("custom_attributes->>'stripe_customer_id' = ?", subscription.customer).first
  end

  def marketplace_subscription?
    subscription.metadata['relationship_type'] == 'marketplace'
  end

  # Checkout sessions created by PlanCheckoutService/EnterprisePaymentLinkService always
  # stamp `plan_name` on the subscription metadata, so we trust that first - it works even
  # for ad-hoc (price_data) Enterprise sessions that have no pre-configured Price/Product ID.
  # Falls back to matching CHATWOOT_CLOUD_PLANS by product/price ID for the older
  # CreateStripeCustomerService auto-subscribe flow, which sets no metadata.
  def resolve_plan
    plan_name = subscription.metadata['plan_name']
    return { 'name' => plan_name } if plan_name.present?

    find_plan(subscription['plan']['product'], subscription['plan']['id']) if subscription['plan'].present?
  end

  def find_plan(product_id, price_id)
    cloud_plans = InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || []
    cloud_plans.find { |config| config['product_id'].include?(product_id) || config['price_ids'].include?(price_id) }
  end
end
