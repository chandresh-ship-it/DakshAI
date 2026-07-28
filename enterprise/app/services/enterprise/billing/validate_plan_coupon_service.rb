# Validates an optional billing coupon for a plan purchase and returns pricing.
class Enterprise::Billing::ValidatePlanCouponService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  class Error < StandardError; end

  pattr_initialize [:plan_name!, :country!, :coupon_code]

  def perform
    raise Error, 'Invalid plan name' unless %w[Hobby Standard Business].include?(plan_name)

    plan = find_plan
    raise Error, 'Plan is not available' if plan.blank? || plan['enabled'] == false

    base_amount = plan['price_per_agent'].to_f
    provider = Enterprise::Billing::PaymentGatewayRegistry.resolve_provider(country: country)
    currency = Enterprise::Billing::PaymentGatewayRegistry.currency_for(provider)
    coupon = resolve_coupon

    {
      plan_name: plan_name,
      payment_provider: provider,
      currency: currency,
      original_amount: base_amount,
      discounted_amount: coupon.present? ? coupon.discounted_amount(base_amount) : base_amount,
      coupon: coupon_payload(coupon)
    }
  end

  private

  def find_plan
    (InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || [])
      .find { |config| config['name'] == plan_name }
  end

  def resolve_coupon
    return nil if coupon_code.blank?

    Enterprise::Billing::ApplyBillingCouponService.new(code: coupon_code, context: 'plan').perform
  end

  def coupon_payload(coupon)
    return nil if coupon.blank?

    {
      code: coupon.code,
      name: coupon.name,
      discount_label: coupon.discount_label,
      discount_type: coupon.discount_type,
      percent_off: coupon.percent_off&.to_f,
      amount_off: coupon.amount_off&.to_f,
      currency: coupon.currency,
      duration: coupon.duration,
      applies_to: coupon.applies_to
    }
  end
end
