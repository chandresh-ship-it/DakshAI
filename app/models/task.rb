class Task < ApplicationRecord
  belongs_to :account
  belongs_to :assignee, class_name: 'User', optional: true
  has_many :contact_tasks, dependent: :destroy
  has_many :contacts, through: :contact_tasks

  validates :title, presence: true
  validates :account_id, presence: true
end
