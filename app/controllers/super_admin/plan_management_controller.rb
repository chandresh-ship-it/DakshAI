class SuperAdmin::PlanManagementController < SuperAdmin::ApplicationController
  PLANS_CONFIG = 'CHATWOOT_CLOUD_PLANS'
  PLAN_FEATURES_CONFIG = 'CHATWOOT_CLOUD_PLAN_FEATURES'

  def show
    load_plans
    load_plan_features
    load_all_features
  end

  def update
    save_plans
    save_plan_features
    redirect_to super_admin_plan_management_path, notice: 'Plans updated successfully.'
  end

  private

  def load_plans
    config = InstallationConfig.find_by(name: PLANS_CONFIG)
    @plans = config&.value || []
    seed_default_plans! if @plans.empty?
  end

  def load_plan_features
    config = InstallationConfig.find_by(name: PLAN_FEATURES_CONFIG)
    @plan_features = config&.value || {}
  end

  def load_all_features
    @all_features = YAML.load_file(Rails.root.join('config/features.yml'))
                        .reject { |f| f['deprecated'] }
                        .map { |f| { 'name' => f['name'], 'display_name' => f['display_name'] } }
  end

  def save_plans
    plans_param = params[:plans] || {}
    config = InstallationConfig.find_or_create_by!(name: PLANS_CONFIG)

    updated_plans = (config.value || []).map do |plan|
      plan_data = plans_param[plan['name']]
      next plan unless plan_data

      plan.merge(
        'price_per_agent' => plan_data[:price_per_agent].to_f,
        'enabled' => plan_data[:enabled] == '1'
      )
    end

    config.update!(value: updated_plans)
  end

  def save_plan_features
    features_param = params[:plan_features] || {}
    config = InstallationConfig.find_or_create_by!(name: PLAN_FEATURES_CONFIG)

    updated_features = {}
    features_param.each do |plan_name, feature_list|
      updated_features[plan_name] = Array(feature_list).reject(&:blank?)
    end

    config.update!(value: updated_features)
  end

  def seed_default_plans!
    all_feature_names = YAML.load_file(Rails.root.join('config/features.yml'))
                            .reject { |f| f['deprecated'] }
                            .map { |f| f['name'] }

    starter_features = all_feature_names.reject { |f| f.in?(premium_only_features) }

    plans = [
      { 'name' => 'Starter', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 0, 'enabled' => true },
      { 'name' => 'Business', 'product_id' => [], 'price_ids' => [], 'price_per_agent' => 19, 'enabled' => true }
    ]

    plan_features = {
      'Starter' => starter_features,
      'Business' => all_feature_names
    }

    InstallationConfig.find_or_create_by!(name: PLANS_CONFIG).update!(value: plans)
    InstallationConfig.find_or_create_by!(name: PLAN_FEATURES_CONFIG).update!(value: plan_features)

    @plans = plans
    @plan_features = plan_features
  end

  def premium_only_features
    %w[
      disable_branding audit_logs sla custom_roles captain_integration
      captain_v1_action_classifier help_center_embedding_search custom_tools
      advanced_search advanced_search_indexing saml captain_integration_v2
      captain_document_auto_sync white_labeling custom_domain reseller_dashboard
      api_access companies csat_review_notes conversation_required_attributes
      advanced_assignment channel_voice
    ]
  end
end
