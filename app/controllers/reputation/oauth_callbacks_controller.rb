# Handles OAuth callback for both Google Business Profile and Facebook Pages.
# URL: GET /reputation/oauth/callback?provider=google&code=...&state=...
class Reputation::OauthCallbacksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    result = Reputation::OauthService.new(
      account: current_account,
      provider: params[:provider],
      code: params[:code]
    ).connect!

    # rubocop:disable Rails/I18nLocaleTexts
    if result
      redirect_to app_reputation_url(account_id: current_account.id), notice: 'Connected successfully.'
    else
      redirect_to app_reputation_url(account_id: current_account.id), alert: 'Connection failed.'
    end
  rescue StandardError => e
    ChatwootExceptionTracker.new(e).capture_exception
    redirect_to app_reputation_url(account_id: current_account.id), alert: 'OAuth error.'
    # rubocop:enable Rails/I18nLocaleTexts
  end

  private

  def current_account
    @current_account ||= Account.find(params[:state] || params[:account_id])
  end
end
