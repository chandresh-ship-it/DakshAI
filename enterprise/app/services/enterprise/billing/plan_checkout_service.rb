# Creates a real Stripe Checkout session so an account can purchase one of the
# self-serve cloud plans (Hobby/Standard/Business). Requires the plan's Stripe
# Price ID to have been configured in Super Admin > Plan Management first.
#
# Not used for Enterprise (negotiated - see EnterprisePaymentLinkService). If the
# account already has an active *real* Stripe subscription (as opposed to one set
# via the dev-only bypass_plan), a new Checkout session would create a second,
# duplicate subscription - so we return a Stripe billing portal link instead,
# where Stripe handles the plan change/proration safely.
class Enterprise::Billing::PlanCheckoutService
  CLOUD_PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'.freeze

  class Error < StandardError; end

  pattr_initialize [:account!, :plan_name!, :success_url!, :cancel_url!]

  def perform
    return { checkout_url: billing_portal_url } if already_on_real_stripe_subscription?
    raise Error, 'This plan is not available for online purchase yet. Please contact support.' if price_id.blank?

    session = Stripe::Checkout::Session.create(
      mode: 'subscription',
      customer: find_or_create_customer,
      line_items: [{ price: price_id, quantity: 1 }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: session_metadata,
      subscription_data: { metadata: session_metadata }
    )

    { checkout_url: session.url }
  end

  private

  def already_on_real_stripe_subscription?
    sub = account.subscription
    sub.present? && sub.relationship_type == 'platform' && sub.stripe_subscription_id.present? && sub.active?
  end

  def billing_portal_url
    Enterprise::Billing::CreateSessionService.new.create_session(find_or_create_customer, success_url).url
  end

  def session_metadata
    { relationship_type: 'platform', account_id: account.id.to_s, plan_name: plan_name }
  end

  def plan
    @plan ||= (InstallationConfig.find_by(name: CLOUD_PLANS_CONFIG)&.value || [])
              .find { |config| config['name'] == plan_name }
  end

  def price_id
    plan&.dig('price_ids')&.first
  end

  def find_or_create_customer
    customer_id = account.custom_attributes['stripe_customer_id']
    if customer_id.blank?
      customer = Stripe::Customer.create(
        name: account.name,
        email: account.administrators.first&.email,
        metadata: { account_id: account.id.to_s }
      )
      customer_id = customer.id
      account.update!(custom_attributes: (account.custom_attributes || {}).merge('stripe_customer_id' => customer_id))
    end
    customer_id
  end
end
