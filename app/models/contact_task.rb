class ContactTask < ApplicationRecord
  belongs_to :contact
  belongs_to :task
end
