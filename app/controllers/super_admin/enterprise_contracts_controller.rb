class SuperAdmin::EnterpriseContractsController < SuperAdmin::ApplicationController
  # Lets "Set Plan" links from the Enterprise Inquiries page pre-fill the account
  # and sensible contract defaults, e.g. /super_admin/enterprise_contracts/new?account_id=61
  def new_resource
    resource_class.new(
      account_id: params[:account_id],
      billing_interval: 'monthly',
      contract_start_date: Time.zone.today,
      contract_end_date: 1.year.from_now.to_date
    )
  end

  def resource_params
    params = super
    if params[:negotiated_limit_overrides].is_a?(ActionController::Parameters) || params[:negotiated_limit_overrides].is_a?(Hash)
      # Convert valid string numbers to integers and remove blanks
      overrides = {}
      params[:negotiated_limit_overrides].each do |k, v|
        next if v.blank?
        overrides[k] = v.to_i if v.to_s.match?(/\A\d+\z/)
      end
      params[:negotiated_limit_overrides] = overrides
    elsif params[:negotiated_limit_overrides].blank?
      params[:negotiated_limit_overrides] = {}
    end

    if params[:negotiated_features].is_a?(Array)
      params[:negotiated_features].reject!(&:blank?)
    end

    params
  end
end
