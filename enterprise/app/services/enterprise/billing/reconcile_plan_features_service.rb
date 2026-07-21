class Enterprise::Billing::ReconcilePlanFeaturesService
  pattr_initialize [:account!]

  def perform
    plan_name = account.custom_attributes['plan_name'].presence || 'Hobby'
    plan_key = plan_name.downcase

    # Fetch baseline features and limits from DB templates
    limits_and_features = PlanFeatureLimit.where(plan_key: plan_key)

    enabled_features = []
    disabled_features = []
    limits_hash = {}

    limits_and_features.each do |pfl|
      if %w[seats contacts conversations t3_subaccounts automations ai_credits].include?(pfl.feature_key)
        # It's a resource limit
        limits_hash[pfl.feature_key] = pfl.limit_value
      elsif pfl.enabled
        # It's a boolean feature flag
        enabled_features << pfl.feature_key
      else
        disabled_features << pfl.feature_key
      end
    end

    # Apply active EnterpriseContract overrides if plan is Enterprise
    if plan_key == 'enterprise'
      active_contract = EnterpriseContract.active.find_by(account_id: account.id)
      if active_contract.present?
        active_contract.negotiated_limit_overrides.each do |key, value|
          limits_hash[key] = value
        end
      end
    end

    # Disable all known premium features first to clean slate
    all_known_features = PlanFeatureLimit.where(plan_key: 'enterprise').pluck(:feature_key) - %w[seats contacts conversations t3_subaccounts
                                                                                                 automations ai_credits]
    account.disable_features(*all_known_features)

    # Enable features for current plan
    account.enable_features(*enabled_features)
    account.enable_features(*manually_managed_features)

    # Map numeric limits keys to the Account schema properties
    account.limits = {
      'agents' => limits_hash['seats'],
      'contacts' => limits_hash['contacts'],
      'conversations' => limits_hash['conversations'],
      't3_subaccounts' => limits_hash['t3_subaccounts'],
      'automations' => limits_hash['automations'],
      'ai_credits' => limits_hash['ai_credits']
    }.compact

    account.save!
  end

  private

  def manually_managed_features
    @manually_managed_features ||= Internal::Accounts::InternalAttributesService.new(account).manually_managed_features
  end
end
