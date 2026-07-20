class Enterprise::Api::V1::PricingPanelController < Api::BaseController
  before_action :fetch_account
  before_action :ensure_reseller_account
  before_action :ensure_connected_account, only: [:create]

  def index
    active_prices = @account.marketplace_plan_prices.active
    render json: {
      connected_account: connected_account_payload,
      prices: active_prices.map { |p| price_payload(p) }
    }
  end

  def create
    price = @account.marketplace_plan_prices.build(price_params)
    if price.save
      render json: price_payload(price), status: :created
    else
      render json: { error: price.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  private

  def fetch_account
    @account = current_user.accounts.find(params[:account_id])
    @current_account_user = @account.account_users.find_by(user_id: current_user.id)
    raise Pundit::NotAuthorizedError unless @current_account_user&.administrator?
  end

  def ensure_reseller_account
    render json: { error: 'Pricing panel is only available for reseller accounts' }, status: :forbidden unless @account.is_reseller?
  end

  def ensure_connected_account
    connected = @account.connected_account
    if connected.blank? || !connected.charges_enabled?
      render json: { error: 'You must complete Stripe Connect onboarding first before setting prices' }, status: :forbidden
    end
  end

  def price_params
    params.require(:marketplace_plan_price).permit(:currency, :agency_price)
  end

  def connected_account_payload
    connected = @account.connected_account
    return nil if connected.blank?

    {
      id: connected.id,
      stripe_account_id: connected.stripe_account_id,
      charges_enabled: connected.charges_enabled,
      charge_routing: connected.charge_routing,
      commission_percent: CommissionRule.current_percent_for(@account)
    }
  end

  def price_payload(price)
    {
      id: price.id,
      currency: price.currency,
      agency_price: price.agency_price.to_f,
      commission_percent: price.commission_percent.to_f,
      platform_fee_amount: price.platform_fee_amount.to_f,
      total_amount: price.total_amount.to_f,
      stripe_price_id: price.stripe_price_id,
      active: price.active
    }
  end
end
