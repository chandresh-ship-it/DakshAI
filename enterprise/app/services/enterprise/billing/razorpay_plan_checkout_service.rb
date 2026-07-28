# Creates a Razorpay Subscription for Indian accounts and returns the hosted
# checkout short_url. Requires the plan's Razorpay Plan ID to be configured in
# Super Admin > Plan Management (razorpay_plan_ids).
#
# Optional coupon_code creates a discounted Razorpay plan for this checkout and
# stamps coupon metadata onto subscription notes (gateway-side metadata).
class Enterprise::Billing::RazorpayPlanCheckoutService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze
  # ~10 years of monthly cycles - treated as ongoing until cancelled.
  DEFAULT_TOTAL_COUNT = 120

  class Error < StandardError; end

  pattr_initialize [:account!, :plan_name!, :success_url!, :cancel_url!, :coupon_code]

  def perform
    return { checkout_url: manage_existing_subscription_url } if already_on_real_razorpay_subscription?
    raise Error, 'This plan is not available for Razorpay purchase yet. Please contact support.' if razorpay_plan_id.blank?

    subscription = client.create_subscription(
      plan_id: checkout_plan_id,
      total_count: DEFAULT_TOTAL_COUNT,
      quantity: 1,
      customer_notify: 1,
      notes: session_notes
    )

    upsert_pending_subscription!(subscription)

    checkout_url = subscription['short_url'].presence || success_url
    { checkout_url: checkout_url, provider: 'razorpay', razorpay_subscription_id: subscription['id'] }
  end

  private

  def already_on_real_razorpay_subscription?
    sub = account.subscription
    sub.present? &&
      sub.payment_provider == 'razorpay' &&
      sub.razorpay_subscription_id.present? &&
      sub.status != 'canceled'
  end

  def manage_existing_subscription_url
    # Razorpay has no Stripe-style customer portal; send the user back to billing
    # where they can contact support or wait for the next cycle to settle.
    success_url
  end

  def session_notes
    notes = {
      relationship_type: 'platform',
      account_id: account.id.to_s,
      plan_name: plan_name,
      success_url: success_url,
      cancel_url: cancel_url,
      base_razorpay_plan_id: razorpay_plan_id
    }
    return notes if coupon.blank?

    notes.merge(coupon.gateway_metadata.stringify_keys).merge(
      'discounted_razorpay_plan_id' => checkout_plan_id
    )
  end

  def coupon
    return @coupon if defined?(@coupon)
    return @coupon = nil if coupon_code.blank?

    @coupon = Enterprise::Billing::ApplyBillingCouponService.new(code: coupon_code, context: 'plan').perform
  rescue Enterprise::Billing::ApplyBillingCouponService::Error => e
    raise Error, e.message
  end

  def checkout_plan_id
    @checkout_plan_id ||= coupon.present? ? discounted_plan_id! : razorpay_plan_id
  end

  def discounted_plan_id!
    base = client.fetch_plan(razorpay_plan_id)
    base_amount = base.dig('item', 'amount').to_i
    raise Error, 'Unable to load Razorpay plan amount for coupon discount' if base_amount <= 0

    discounted_amount = discounted_paise(base_amount)
    currency = base.dig('item', 'currency').presence || 'INR'

    created = client.create_plan(
      period: base['period'].presence || 'monthly',
      interval: base['interval'].presence || 1,
      item: {
        name: "#{plan_name} - #{coupon.code}",
        amount: discounted_amount,
        currency: currency,
        description: "Coupon #{coupon.code} (#{coupon.discount_label})"
      },
      notes: coupon.gateway_metadata
    )
    created['id']
  end

  def discounted_paise(base_amount)
    discounted = if coupon.discount_type == 'percent'
                   (base_amount * (1 - (coupon.percent_off.to_f / 100.0))).round
                 else
                   # amount_off is major currency units; Razorpay amounts are paise/cents.
                   base_amount - (coupon.amount_off.to_f * 100).round
                 end
    [discounted, 0].max
  end

  def plan
    @plan ||= (InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || [])
              .find { |config| config['name'] == plan_name }
  end

  def razorpay_plan_id
    plan&.dig('razorpay_plan_ids')&.first.presence || plan&.dig('razorpay_plan_id').presence
  end

  def upsert_pending_subscription!(razorpay_subscription)
    subscription = account.subscription || account.build_subscription
    subscription.assign_attributes(
      payment_provider: 'razorpay',
      relationship_type: 'platform',
      plan_name: plan_name,
      status: razorpay_subscription['status'].presence || 'created',
      razorpay_subscription_id: razorpay_subscription['id'],
      subscribed_quantity: 1
    )
    subscription.save!
  end

  def client
    @client ||= Enterprise::Billing::RazorpayClient.new
  end
end
