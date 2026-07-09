# == Schema Information
#
# Table name: reputation_integrations
#
#  id               :bigint           not null, primary key
#  access_token     :text
#  location_name    :string
#  provider         :string           not null
#  refresh_token    :text
#  status           :string           default("active")
#  token_expires_at :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :bigint           not null
#  location_id      :string           not null
#
# Indexes
#
#  idx_reputation_integrations_unique           (account_id,provider,location_id) UNIQUE
#  index_reputation_integrations_on_account_id  (account_id)
#
class Reputation::Integration < ApplicationRecord
  self.table_name = 'reputation_integrations'

  belongs_to :account
  has_many :reputation_reviews, foreign_key: :reputation_integration_id, dependent: :destroy

  encrypts :access_token, :refresh_token

  enum :provider, {
    google: 'google',
    facebook: 'facebook',
    agoda: 'agoda',
    airbnb: 'airbnb',
    aliexpress: 'aliexpress',
    amazon: 'amazon',
    angi: 'angi',
    apple_app_store: 'apple_app_store',
    avvo: 'avvo',
    custom: 'custom'
  }
  enum :status, { active: 'active', disconnected: 'disconnected' }

  validates :provider, :location_id, presence: true
  validates :location_id, uniqueness: { scope: [:account_id, :provider] }
end
