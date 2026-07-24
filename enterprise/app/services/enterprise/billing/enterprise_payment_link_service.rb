# Creates a Stripe Checkout session for a negotiated Enterprise price. Since
# Enterprise pricing isn't a pre-configured Stripe Price, this builds the price
# on the fly via `price_data`. The resulting subscription is tagged with
# `plan_name: 'Enterprise'` in its metadata so HandleStripeEventService can
# activate the Enterprise plan for the account once payment succeeds, without
# needing a matching Product/Price ID in CHATWOOT_CLOUD_PLANS.
class Enterprise::Billing::EnterprisePaymentLinkService
  pattr_initialize [:account!, :monthly_price!, :success_url!, :cancel_url!]

  def perform
    session = Stripe::Checkout::Session.create(
      mode: 'subscription',
      customer: find_or_create_customer,
      customer_update: { name: 'auto', address: 'auto' },
      billing_address_collection: 'required',
      line_items: [{
        price_data: {
          currency: 'usd',
          product_data: { name: "#{account.name} - Enterprise Plan" },
          unit_amount: (monthly_price.to_f * 100).round,
          recurring: { interval: 'month' }
        },
        quantity: 1
      }],
      success_url: success_url,
      cancel_url: cancel_url,
      metadata: session_metadata,
      subscription_data: { metadata: session_metadata }
    )

    { checkout_url: session.url }
  end

  private

  def session_metadata
    { relationship_type: 'platform', account_id: account.id.to_s, plan_name: 'Enterprise' }
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
