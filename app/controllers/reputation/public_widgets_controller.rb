# Public endpoint — no auth required.
# GET /reputation/widget/:token/reviews
# GET /reputation/widget/:token/reviews?rating_min=4
class Reputation::PublicWidgetsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def reviews
    widget = Reputation::Widget.find_by!(token: params[:token])
    return head :not_found unless widget.active?

    reviews = Reputation::Review
              .where(account_id: widget.account_id, status: :replied)
              .where('rating >= ?', widget.min_rating)
              .order(reviewed_at: :desc)
              .limit(20)
              .select(:id, :provider, :rating, :body, :reviewer_name, :reviewed_at)

    render json: { widget: widget.slice(:style, :min_rating, :hide_watermark), reviews: reviews }
  end

  # GET /r/:token  — tracks click and redirects to review platform
  def redirect
    request = Reputation::ReviewRequest.find_by!(token: params[:token])
    request.update!(status: :clicked, clicked_at: Time.current) if request.sent? || request.delivered?
    redirect_to review_url(request), allow_other_host: true
  end

  private

  def review_url(request)
    integration = request.account.reputation_integrations
                         .where(provider: 'google').first
    # ponytail: hardcoded to GBP search fallback — dynamic per-location URL in Phase 5 polish
    integration ? "https://search.google.com/local/writereview?placeid=#{integration.location_id}" : '/'
  end
end
