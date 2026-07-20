class Enterprise::Api::V1::MarketplaceCheckoutController < Api::BaseController
  before_action :fetch_account
  before_action :ensure_marketplace_client

  def create
    currency = params[:currency] || 'usd'
    success_url = params[:success_url].presence || default_return_url
    cancel_url = params[:cancel_url].presence || default_return_url

    service = Enterprise::Billing::Tier3CheckoutService.new(
      account: @account,
      currency: currency,
      success_url: success_url,
      cancel_url: cancel_url
    )

    result = service.perform
    render json: result
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def fetch_account
    @account = current_user.accounts.find(params[:account_id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
    raise Pundit::NotAuthorizedError unless @current_account_user&.administrator?
  end

  def ensure_marketplace_client
    render json: { error: 'Account must have a reseller parent to subscribe' }, status: :forbidden if @account.parent_id.blank?
  end

  def default_return_url
    "#{ENV.fetch('FRONTEND_URL', request.base_url)}/app/accounts/#{@account.id}/settings/billing"
  end
end
