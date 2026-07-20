# == Schema Information
#
# Table name: connected_accounts
#
#  id                :bigint           not null, primary key
#  charge_routing    :string           not null
#  charges_enabled   :boolean          default(FALSE)
#  country           :string           not null
#  onboarding_status :string           default("onboarding_incomplete"), not null
#  payouts_enabled   :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint           not null
#  stripe_account_id :string           not null
#
# Indexes
#
#  index_connected_accounts_on_account_id         (account_id) UNIQUE
#  index_connected_accounts_on_stripe_account_id  (stripe_account_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class ConnectedAccount < ApplicationRecord
  CHARGE_ROUTINGS = %w[destination separate_charge_transfer].freeze
  ONBOARDING_STATUSES = %w[onboarding_incomplete active disabled].freeze

  belongs_to :account

  validates :stripe_account_id, presence: true, uniqueness: true
  validates :country, presence: true
  validates :charge_routing, inclusion: { in: CHARGE_ROUTINGS }
  validates :onboarding_status, inclusion: { in: ONBOARDING_STATUSES }
end
