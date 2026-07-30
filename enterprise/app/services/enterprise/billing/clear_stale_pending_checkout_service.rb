# Cancels an unfinished checkout subscription when the customer switches billing
# country/gateway before paying (e.g. abandoned Razorpay checkout, then picks US/Stripe).
class Enterprise::Billing::ClearStalePendingCheckoutService
  pattr_initialize [:account!, :requested_provider!]

  def perform
    subscription = account.subscription
    return false if subscription.blank?
    return false if subscription.active?
    return false if subscription.status == 'canceled'
    return false if subscription.payment_provider.blank?
    return false if subscription.payment_provider == requested_provider.to_s

    subscription.update!(
      status: 'canceled',
      grace_period_ends_at: nil
    )
    true
  end
end
