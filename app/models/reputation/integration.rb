class Reputation::Integration < ApplicationRecord
  self.table_name = 'reputation_integrations'

  belongs_to :account
  has_many :reputation_reviews, foreign_key: :reputation_integration_id, dependent: :destroy

  encrypts :access_token, :refresh_token

  enum :provider, { google: 'google', facebook: 'facebook' }
  enum :status, { active: 'active', disconnected: 'disconnected' }

  validates :provider, :location_id, presence: true
  validates :location_id, uniqueness: { scope: [:account_id, :provider] }
end
