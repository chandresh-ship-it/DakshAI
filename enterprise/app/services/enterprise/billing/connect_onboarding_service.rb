class Enterprise::Billing::ConnectOnboardingService
  DEFAULT_COUNTRY = 'US'.freeze
  INDIA_COUNTRY_CODE = 'IN'.freeze

  pattr_initialize [:account!]

  def create_onboarding_link(country:, refresh_url:, return_url:)
    connected_account = find_or_create_connected_account(country)
    stripe_account = Stripe::Account.retrieve(connected_account.stripe_account_id)
    update_status!(connected_account, stripe_account)

    account_link = Stripe::AccountLink.create(
      account: connected_account.stripe_account_id,
      refresh_url: refresh_url,
      return_url: return_url,
      type: 'account_onboarding'
    )

    { connected_account: connected_account, onboarding_url: account_link.url }
  end

  def sync_status
    return nil if account.connected_account.blank?

    stripe_account = Stripe::Account.retrieve(account.connected_account.stripe_account_id)
    update_status!(account.connected_account, stripe_account)
  end

  private

  def find_or_create_connected_account(country)
    account.connected_account || create_connected_account(country)
  end

  def create_connected_account(country)
    normalized_country = normalize_country(country)
    stripe_account = Stripe::Account.create(
      type: 'express',
      country: normalized_country,
      email: account.administrators.first&.email,
      business_type: 'company',
      capabilities: {
        card_payments: { requested: true },
        transfers: { requested: true }
      },
      metadata: {
        account_id: account.id.to_s
      }
    )

    account.create_connected_account!(
      stripe_account_id: stripe_account.id,
      country: normalized_country,
      charge_routing: charge_routing_for(normalized_country),
      onboarding_status: onboarding_status_for(stripe_account),
      charges_enabled: stripe_account.charges_enabled,
      payouts_enabled: stripe_account.payouts_enabled
    )
  end

  def update_status!(connected_account, stripe_account)
    connected_account.update!(
      onboarding_status: onboarding_status_for(stripe_account),
      charges_enabled: stripe_account.charges_enabled,
      payouts_enabled: stripe_account.payouts_enabled
    )

    connected_account
  end

  def normalize_country(country)
    country.presence&.upcase || DEFAULT_COUNTRY
  end

  def charge_routing_for(country)
    country == INDIA_COUNTRY_CODE ? 'separate_charge_transfer' : 'destination'
  end

  def onboarding_status_for(stripe_account)
    return 'active' if stripe_account.charges_enabled

    stripe_account.details_submitted ? 'disabled' : 'onboarding_incomplete'
  end
end
