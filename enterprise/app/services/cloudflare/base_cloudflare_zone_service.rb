class Cloudflare::BaseCloudflareZoneService
  BASE_URI = 'https://api.cloudflare.com/client/v4'.freeze

  private

  def headers
    {
      'Authorization' => "Bearer #{api_token}",
      'Content-Type' => 'application/json'
    }
  end

  def api_token
    GlobalConfigService.load('CLOUDFLARE_API_KEY', nil)
  end

  def zone_id
    GlobalConfigService.load('CLOUDFLARE_ZONE_ID', nil)
  end

  def update_ssl_settings(record, data)
    verification_record = data['ownership_verification_http']
    ssl_record = data['ssl']
    verification_errors = data['verification_errors']&.first || ''

    # Start with existing settings to preserve verification data if it exists
    ssl_settings = record.ssl_settings || {}

    # Only update verification fields if they exist in the response (during initial setup)
    if verification_record.present?
      ssl_settings['cf_verification_id'] = verification_record['http_url'].split('/').last
      ssl_settings['cf_verification_body'] = verification_record['http_body']
    end

    # Always update SSL status and errors from current response
    ssl_settings['cf_status'] = ssl_record&.dig('status')
    ssl_settings['cf_verification_errors'] = verification_errors

    record.update(ssl_settings: ssl_settings)
  end
end
