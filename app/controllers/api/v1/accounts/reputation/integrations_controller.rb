class Api::V1::Accounts::Reputation::IntegrationsController < Api::V1::Accounts::BaseController
  before_action :integration, only: [:destroy]

  # GET /api/v1/accounts/:account_id/reputation/integrations
  def index
    render json: current_account.reputation_integrations.order(created_at: :desc).as_json(
      only: [:id, :provider, :location_id, :location_name, :status, :created_at]
    )
  end

  # POST /api/v1/accounts/:account_id/reputation/integrations
  def create
    integration = current_account.reputation_integrations.new(integration_params)
    integration.status = :active

    # Since OAuth is bypassed, set a location ID if not present
    integration.location_id ||= SecureRandom.uuid

    if integration.save
      seed_mock_reviews(integration) unless %w[google facebook].include?(integration.provider)
      render json: integration.as_json(
        only: [:id, :provider, :location_id, :location_name, :status, :created_at]
      ), status: :created
    else
      render json: { errors: integration.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/:account_id/reputation/integrations/:id
  def destroy
    @integration.destroy!
    head :no_content
  end

  private

  def integration
    @integration ||= current_account.reputation_integrations.find(params[:id])
  end

  def integration_params
    params.require(:integration).permit(:provider, :location_id, :location_name)
  end

  # rubocop:disable Metrics/MethodLength
  def seed_mock_reviews(integration)
    templates = [
      {
        reviewer_name: 'Sarah Jenkins',
        rating: 5,
        body: 'Absolutely wonderful experience! The service was prompt, professional, and went above and beyond my expectations.',
        reviewed_at: 1.day.ago
      },
      {
        reviewer_name: 'Michael Chen',
        rating: 4,
        body: 'Very satisfied with the quality of the listing and overall communication. Will recommend it to everyone.',
        reviewed_at: 3.days.ago
      },
      {
        reviewer_name: 'David K.',
        rating: 5,
        body: 'Fantastic! Easy to use and got exactly what I needed. Five stars all the way.',
        reviewed_at: 5.days.ago
      }
    ]

    templates.each do |t|
      integration.reputation_reviews.create!(
        account: integration.account,
        provider: integration.provider,
        external_id: "mock_#{integration.provider}_#{SecureRandom.hex(4)}",
        reviewer_name: t[:reviewer_name],
        rating: t[:rating],
        body: t[:body],
        status: :pending,
        reviewed_at: t[:reviewed_at]
      )
    end
  end
  # rubocop:enable Metrics/MethodLength
end
