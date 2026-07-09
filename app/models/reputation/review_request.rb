class Reputation::ReviewRequest < ApplicationRecord
  self.table_name = 'reputation_review_requests'

  belongs_to :account
  belongs_to :reputation_template, class_name: 'Reputation::Template'
  belongs_to :contact
  has_one :reputation_feedback_submission, class_name: 'Reputation::FeedbackSubmission',
                                           foreign_key: :reputation_review_request_id, dependent: :destroy

  enum :channel, { sms: 'sms', email: 'email' }
  enum :status, { sent: 'sent', delivered: 'delivered', clicked: 'clicked', completed: 'completed' }

  validates :token, :channel, presence: true
  validates :token, uniqueness: true

  before_validation :set_token, on: :create

  private

  def set_token
    self.token ||= SecureRandom.urlsafe_base64(16)
  end
end
