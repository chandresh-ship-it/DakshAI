class Reputation::Template < ApplicationRecord
  self.table_name = 'reputation_templates'

  belongs_to :account
  has_many :reputation_review_requests, class_name: 'Reputation::ReviewRequest',
                                        foreign_key: :reputation_template_id, dependent: :nullify

  enum :channel, { sms: 'sms', email: 'email' }

  validates :name, :channel, :body, presence: true
  validates :subject, presence: true, if: :email?
end
