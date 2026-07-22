module CheckAccountLimits
  extend ActiveSupport::Concern

  included do
    before_action :enforce_account_limits!, only: [:create, :bulk_create]
  end

  private

  def enforce_account_limits!
    # Map the controller name to the corresponding resource limit key
    limit_key = case controller_name
                when 'agents', 'account_users'
                  'agents'
                when 'inboxes'
                  'inboxes'
                when 'contacts'
                  'contacts'
                when 'conversations'
                  'conversations'
                when 'automation_rules'
                  'automations'
                else
                  nil
                end

    return unless limit_key

    # Retrieve the configured limit for this account (nil means unlimited)
    limit_value = Current.account.limits[limit_key]
    return if limit_value.blank?

    # Count the current usage of the resource
    current_count = current_resource_count_for_limit(limit_key)
    
    # If this is a bulk create action, add the incoming count
    incoming_count = 1
    incoming_count = params[:emails].length if action_name == 'bulk_create' && params[:emails].is_a?(Array)

    if (current_count + incoming_count) > limit_value.to_i
      render_payment_required("Account #{limit_key} limit exceeded. Please upgrade your plan.")
    end
  end

  def current_resource_count_for_limit(limit_key)
    case limit_key
    when 'agents'
      Current.account.agents.count
    when 'inboxes'
      Current.account.inboxes.count
    when 'contacts'
      Current.account.contacts.count
    when 'conversations'
      Current.account.conversations.count
    when 'automations'
      Current.account.automation_rules.count
    else
      0
    end
  end
end
