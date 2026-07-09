class Reputation::FeedbackSubmission < ApplicationRecord
  self.table_name = 'reputation_feedback_submissions'

  belongs_to :account
  belongs_to :reputation_review_request, class_name: 'Reputation::ReviewRequest'

  validates :rating, presence: true, inclusion: { in: 1..3 }
end
