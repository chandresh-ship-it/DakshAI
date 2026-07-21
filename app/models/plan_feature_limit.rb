class PlanFeatureLimit < ApplicationRecord
  PLAN_KEYS = %w[hobby standard business enterprise].freeze

  validates :plan_key, presence: true, inclusion: { in: PLAN_KEYS }
  validates :feature_key, presence: true, uniqueness: { scope: :plan_key }
  validates :enabled, inclusion: { in: [true, false] }
  validates :limit_value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
