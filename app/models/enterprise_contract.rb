class EnterpriseContract < ApplicationRecord
  belongs_to :account
  belongs_to :negotiated_by_user, class_name: 'User', optional: true

  validates :account_id, presence: true, uniqueness: true
  validates :negotiated_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :billing_interval, presence: true, inclusion: { in: %w[monthly annual] }
  validates :collection_method, presence: true, inclusion: { in: %w[send_invoice charge_automatically] }
  validates :payment_terms_days, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :contract_start_date, presence: true
  validates :contract_end_date, presence: true

  validate :end_date_must_be_after_start_date
  validate :negotiated_limit_overrides_format

  scope :active, ->(date = Time.zone.today) { where('contract_start_date <= ? AND contract_end_date >= ?', date, date) }

  private

  def end_date_must_be_after_start_date
    return if contract_start_date.blank? || contract_end_date.blank?

    return unless contract_end_date < contract_start_date

    errors.add(:contract_end_date, 'must be after the contract start date')
  end

  def negotiated_limit_overrides_format
    return if negotiated_limit_overrides.blank?

    unless negotiated_limit_overrides.is_a?(Hash)
      errors.add(:negotiated_limit_overrides, 'must be a JSON/Hash')
      return
    end

    negotiated_limit_overrides.each do |key, value|
      unless value.nil? || (value.is_a?(Integer) && value >= 0)
        errors.add(:negotiated_limit_overrides, "override for '#{key}' must be a non-negative integer or null")
      end
    end
  end
end
