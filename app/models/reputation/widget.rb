class Reputation::Widget < ApplicationRecord
  self.table_name = 'reputation_widgets'

  belongs_to :account

  enum :style, { carousel: 'carousel', grid: 'grid', badge: 'badge' }

  validates :name, :token, presence: true
  validates :token, uniqueness: true
  validates :min_rating, inclusion: { in: 1..5 }

  before_validation :set_token, on: :create

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(12)
  end
end
