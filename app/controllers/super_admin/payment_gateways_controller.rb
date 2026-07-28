class SuperAdmin::PaymentGatewaysController < SuperAdmin::ApplicationController
  def show
    @gateways = Enterprise::Billing::PaymentGatewayRegistry.admin_view
  end

  def update
    Enterprise::Billing::PaymentGatewayRegistry.save!(params[:gateways] || {})
    redirect_to super_admin_payment_gateways_path, notice: 'Payment gateway settings updated.'
  end
end
