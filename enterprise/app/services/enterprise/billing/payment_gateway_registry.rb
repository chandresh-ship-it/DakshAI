# Central registry for billing payment gateways. Super Admin toggles which gateways
# are enabled and which countries they serve; new gateways are added to DEFINITIONS
# in code (env keys, currency, label) and automatically appear in the admin UI.
class Enterprise::Billing::PaymentGatewayRegistry
  CONFIG_NAME = 'BILLING_PAYMENT_GATEWAYS'.freeze

  DEFINITIONS = {
    'stripe' => {
      label: 'Stripe',
      currency: 'usd',
      env_keys: %w[STRIPE_SECRET_KEY]
    },
    'razorpay' => {
      label: 'Razorpay',
      currency: 'inr',
      env_keys: %w[RAZORPAY_KEY_ID RAZORPAY_KEY_SECRET]
    }
  }.freeze

  class << self
    def definitions
      DEFINITIONS
    end

    def configured?(gateway_id)
      definition = DEFINITIONS[gateway_id.to_s]
      return false if definition.blank?

      definition[:env_keys].all? { |key| ENV[key].present? }
    end

    def load_config
      raw = InstallationConfig.find_by(name: CONFIG_NAME)&.value
      merge_with_defaults(raw.presence || default_config)
    end

    def default_config
      DEFINITIONS.keys.map do |id|
        {
          'id' => id,
          'enabled' => true,
          'country_codes' => id == 'razorpay' ? ['IN'] : []
        }
      end
    end

    def enabled_gateways
      load_config.select { |gateway| gateway_enabled?(gateway) }
    end

    def enabled?(gateway_id)
      enabled_gateways.any? { |gateway| gateway['id'] == gateway_id.to_s }
    end

    def resolve_provider(country:, locked_provider: nil)
      return locked_provider.to_s if locked_provider.present? && enabled?(locked_provider)

      normalized_country = country.to_s.strip.upcase.presence
      gateways = enabled_gateways
      return 'stripe' if gateways.blank?

      country_match = gateways.find do |gateway|
        codes = normalized_country_codes(gateway['country_codes'])
        codes.present? && codes.include?(normalized_country)
      end
      return country_match['id'] if country_match

      wildcard = gateways.find { |gateway| normalized_country_codes(gateway['country_codes']).blank? }
      return wildcard['id'] if wildcard

      gateways.first['id']
    end

    def default_country_for(gateway_id)
      gateway = load_config.find { |entry| entry['id'] == gateway_id.to_s }
      normalized_country_codes(gateway&.dig('country_codes')).first.presence ||
        (gateway_id.to_s == 'razorpay' ? 'IN' : 'US')
    end

    def currency_for(gateway_id)
      DEFINITIONS.dig(gateway_id.to_s, :currency) || 'usd'
    end

    def label_for(gateway_id)
      DEFINITIONS.dig(gateway_id.to_s, :label) || gateway_id.to_s.capitalize
    end

    def public_config
      enabled_gateways.map do |gateway|
        {
          id: gateway['id'],
          label: label_for(gateway['id']),
          currency: currency_for(gateway['id']),
          country_codes: normalized_country_codes(gateway['country_codes'])
        }
      end
    end

    def admin_view
      load_config.map do |gateway|
        gateway.merge(
          'label' => label_for(gateway['id']),
          'currency' => currency_for(gateway['id']),
          'configured' => configured?(gateway['id']),
          'country_codes_text' => normalized_country_codes(gateway['country_codes']).join(', ')
        )
      end
    end

    def save!(gateways_param)
      entries = DEFINITIONS.keys.map do |id|
        row = gateways_param[id] || gateways_param[id.to_sym] || {}
        enabled = row[:enabled] == '1' || row['enabled'] == '1'
        country_text = row[:country_codes].presence || row['country_codes'].presence || ''
        {
          'id' => id,
          'enabled' => enabled,
          'country_codes' => parse_country_codes(country_text)
        }
      end

      config = InstallationConfig.find_or_initialize_by(name: CONFIG_NAME)
      config.value = entries
      config.save!
      load_config
    end

    private

    def merge_with_defaults(raw)
      saved_by_id = Array(raw).each_with_object({}) do |entry, memo|
        memo[entry['id'].to_s] = entry if entry['id'].present?
      end

      default_config.map do |default_entry|
        saved = saved_by_id[default_entry['id']]
        next default_entry if saved.blank?

        default_entry.merge(saved).merge(
          'country_codes' => normalized_country_codes(saved['country_codes'].presence || default_entry['country_codes'])
        )
      end
    end

    def gateway_enabled?(gateway)
      gateway['enabled'] != false && configured?(gateway['id'])
    end

    def normalized_country_codes(value)
      Array(value).filter_map { |code| code.to_s.strip.upcase.presence }.uniq
    end

    def parse_country_codes(text)
      text.to_s.split(/[,\s]+/).filter_map { |code| code.strip.upcase.presence }.uniq
    end
  end
end
