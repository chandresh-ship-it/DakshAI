class CommissionRule < ApplicationRecord
  belongs_to :account
  belongs_to :created_by_user, class_name: 'User', optional: true

  validates :commission_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :effective_from, presence: true

  scope :active_at, ->(time) { where('effective_from <= ?', time).order(effective_from: :desc) }

  def self.current_percent_for(account)
    active_at(Time.current).find_by(account: account)&.commission_percent || 30.0
  end
end
