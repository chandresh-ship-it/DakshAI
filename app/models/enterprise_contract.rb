# == Schema Information
#
# Table name: enterprise_contracts
#
#  id                         :bigint           not null, primary key
#  auto_renew                 :boolean          default(FALSE)
#  billing_interval           :string           not null
#  collection_method          :string           default("send_invoice"), not null
#  contract_end_date          :date             not null
#  contract_start_date        :date             not null
#  currency                   :string           not null
#  negotiated_features        :jsonb
#  negotiated_limit_overrides :jsonb
#  negotiated_price           :decimal(10, 2)   not null
#  notes                      :text
#  payment_terms_days         :integer          default(30)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  account_id                 :bigint           not null
#  negotiated_by_user_id      :bigint
#
# Indexes
#
#  index_enterprise_contracts_on_account_id             (account_id)
#  index_enterprise_contracts_on_negotiated_by_user_id  (negotiated_by_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (negotiated_by_user_id => users.id)
#
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

  before_validation :set_defaults

  private

  def set_defaults
    self.currency ||= 'USD'
    self.collection_method ||= 'charge_automatically'

    if new_record? && negotiated_features.blank?
      self.negotiated_features = PlanFeatureLimit.where(plan_key: 'enterprise', enabled: true).pluck(:feature_key)
    end
  end

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
