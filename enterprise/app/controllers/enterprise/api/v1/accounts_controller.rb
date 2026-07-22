class Enterprise::Api::V1::AccountsController < Api::BaseController
  include BillingHelper
  before_action :fetch_account
  before_action :check_authorization
  before_action :check_cloud_env, only: [:toggle_deletion]

  def subscription
    if stripe_customer_id.blank? && @account.custom_attributes['is_creating_customer'].blank?
      @account.update(custom_attributes: { is_creating_customer: true })
      Enterprise::CreateStripeCustomerJob.perform_later(@account)
    end
    head :no_content
  end

  def limits
    limits = default_limits

    # Only fall back to Chatwoot's hardcoded free-tier caps when the custom plan
    # matrix has not written any limits for this account yet.
    if default_plan?(@account) && @account.limits.blank?
      limits.merge!(
        'conversation' => {
          'allowed' => 500,
          'consumed' => conversations_this_month(@account)
        },
        'non_web_inboxes' => {
          'allowed' => 0,
          'consumed' => non_web_inboxes(@account)
        },
        'agents' => {
          'allowed' => 2,
          'consumed' => agents(@account)
        }
      )
    end

    # include id in response to ensure that the store can be updated on the frontend
    render json: { id: @account.id, limits: limits }, status: :ok
  end

  def checkout
    return create_stripe_billing_session(stripe_customer_id) if stripe_customer_id.present?

    render_invalid_billing_details
  end

  def toggle_deletion
    action_type = params[:action_type]

    case action_type
    when 'delete'
      mark_for_deletion
    when 'undelete'
      unmark_for_deletion
    else
      render json: { error: 'Invalid action_type. Must be either "delete" or "undelete"' }, status: :unprocessable_entity
    end
  end

  def topup_checkout
    return render json: { error: I18n.t('errors.topup.credits_required') }, status: :unprocessable_entity if params[:credits].blank?

    service = Enterprise::Billing::TopupCheckoutService.new(account: @account)
    result = service.create_checkout_session(credits: params[:credits].to_i)

    @account.reload
    render json: result.merge(
      id: @account.id,
      limits: @account.limits,
      custom_attributes: @account.custom_attributes
    )
  rescue Enterprise::Billing::TopupCheckoutService::Error, Stripe::StripeError => e
    render_could_not_create_error(e.message)
  end

  def bypass_plan
    plan_name = params[:plan_name]
    return render json: { error: 'Invalid plan name' }, status: :unprocessable_entity unless %w[Hobby Standard Business
                                                                                                Enterprise].include?(plan_name)

    @account.update_column(:custom_attributes, @account.custom_attributes.merge('plan_name' => plan_name))
    @account.reload

    # Ensure a subscription record exists so it shows up in Super Admin
    subscription = @account.subscription || @account.build_subscription
    subscription.assign_attributes(
      plan_name: plan_name,
      status: 'active',
      relationship_type: 'platform',
      subscribed_quantity: 1,
      current_period_start: Time.current,
      current_period_end: 10.years.from_now
    )
    subscription.save!

    Enterprise::Billing::ReconcilePlanFeaturesService.new(account: @account).perform

    render json: {
      message: "Plan updated to #{plan_name}",
      limits: @account.limits,
      custom_attributes: @account.custom_attributes
    }, status: :ok
  end

  private

  def check_cloud_env
    render json: { error: 'Not found' }, status: :not_found unless ChatwootApp.chatwoot_cloud?
  end

  def default_limits
    {
      'conversation' => {
        'allowed' => plan_limit('conversations'),
        'consumed' => conversations_this_month(@account)
      },
      'non_web_inboxes' => {
        'allowed' => @account.usage_limits[:inboxes] || @account.usage_limits[:non_web_inboxes],
        'consumed' => non_web_inboxes(@account)
      },
      'agents' => {
        'allowed' => @account.usage_limits[:agents],
        'consumed' => agents(@account)
      },
      'contacts' => {
        'allowed' => plan_limit('contacts'),
        'consumed' => @account.contacts.count
      },
      'automations' => {
        'allowed' => plan_limit('automations'),
        'consumed' => @account.automation_rules.count
      },
      't3_subaccounts' => {
        'allowed' => plan_limit('t3_subaccounts'),
        'consumed' => @account.sub_accounts.count
      },
      'captain' => @account.usage_limits[:captain]
    }
  end

  # A missing key in account.limits means the plan matrix left this resource
  # unlimited (ReconcilePlanFeaturesService drops nil limit_value entries),
  # so fall back to the "no limit" sentinel instead of 0.
  def plan_limit(key)
    @account.limits[key] || ChatwootApp.max_limit
  end

  def fetch_account
    @account = current_user.accounts.find(params[:id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
  end

  def stripe_customer_id
    @account.custom_attributes['stripe_customer_id']
  end

  def mark_for_deletion
    reason = 'manual_deletion'

    if @account.mark_for_deletion(reason)
      cancel_cloud_subscriptions_for_deletion

      render json: { message: 'Account marked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def unmark_for_deletion
    if @account.unmark_for_deletion
      render json: { message: 'Account unmarked for deletion' }, status: :ok
    else
      render json: { message: @account.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def render_invalid_billing_details
    render_could_not_create_error('Please subscribe to a plan before viewing the billing details')
  end

  def create_stripe_billing_session(customer_id)
    session = Enterprise::Billing::CreateSessionService.new.create_session(customer_id)
    render_redirect_url(session.url)
  end

  def cancel_cloud_subscriptions_for_deletion
    Enterprise::Billing::CancelCloudSubscriptionsService.new(account: @account).perform
  rescue Stripe::StripeError => e
    Rails.logger.warn("Failed to cancel cloud subscriptions for account #{@account.id}: #{e.class} - #{e.message}")
  end

  def render_redirect_url(redirect_url)
    render json: { redirect_url: redirect_url }
  end

  def pundit_user
    {
      user: current_user,
      account: @account,
      account_user: @current_account_user
    }
  end
end
