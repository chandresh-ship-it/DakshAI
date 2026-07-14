class Enterprise::CloudflareVerificationJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id)
    record = record_type.constantize.find_by(id: record_id)
    return unless record && record.custom_domain.present?

    result = check_hostname_status(record)

    create_hostname(record) if result[:errors].present?
  end

  private

  def create_hostname(record)
    Cloudflare::CreateCustomHostnameService.new(record: record).perform
  end

  def check_hostname_status(record)
    Cloudflare::CheckCustomHostnameService.new(record: record).perform
  end
end
