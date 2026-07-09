class Reputation::Review < ApplicationRecord
  self.table_name = 'reputation_reviews'

  belongs_to :account
  belongs_to :reputation_integration, class_name: 'Reputation::Integration'
  has_one :reputation_review_reply, class_name: 'Reputation::ReviewReply', foreign_key: :reputation_review_id, dependent: :destroy

  enum :provider, { google: 'google', facebook: 'facebook' }
  enum :status, { pending: 'pending', replied: 'replied', ignored: 'ignored' }

  validates :external_id, :provider, :rating, presence: true
  validates :rating, inclusion: { in: 1..5 }
  validates :external_id, uniqueness: { scope: [:account_id, :provider] }
end
