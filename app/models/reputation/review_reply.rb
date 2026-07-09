class Reputation::ReviewReply < ApplicationRecord
  self.table_name = 'reputation_review_replies'

  belongs_to :reputation_review, class_name: 'Reputation::Review'
  belongs_to :account

  enum :status, { draft: 'draft', published: 'published' }

  validates :body, presence: true
end
