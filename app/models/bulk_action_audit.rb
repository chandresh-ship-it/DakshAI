class BulkActionAudit < ApplicationRecord
  belongs_to :account
  belongs_to :user

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  validates :action_label, presence: true
  validates :operation_type, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
end
