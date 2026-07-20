class Subscription < ApplicationRecord
  belongs_to :account
  belongs_to :connected_account, optional: true

  validates :relationship_type, presence: true, inclusion: { in: %w[platform marketplace] }
  validates :status, presence: true

  scope :active, -> { where(status: %w[active trialing]) }
  scope :platform, -> { where(relationship_type: 'platform') }
  scope :marketplace, -> { where(relationship_type: 'marketplace') }

  def active?
    %w[active trialing].include?(status)
  end
end
