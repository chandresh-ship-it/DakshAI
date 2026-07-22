# == Schema Information
#
# Table name: plan_feature_limits
#
#  id          :bigint           not null, primary key
#  enabled     :boolean          default(FALSE), not null
#  feature_key :string           not null
#  limit_value :integer
#  plan_key    :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_plan_feature_limits_on_plan_key_and_feature_key  (plan_key,feature_key) UNIQUE
#
class PlanFeatureLimit < ApplicationRecord
  PLAN_KEYS = %w[hobby standard business enterprise].freeze

  validates :plan_key, presence: true, inclusion: { in: PLAN_KEYS }
  validates :feature_key, presence: true, uniqueness: { scope: :plan_key }
  validates :enabled, inclusion: { in: [true, false] }
  validates :limit_value, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
