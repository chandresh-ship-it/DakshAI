class SuperAdmin::EnterpriseContractsController < SuperAdmin::ApplicationController
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
