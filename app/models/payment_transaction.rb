# == Schema Information
#
# Table name: payment_transactions
#
#  id                 :bigint           not null, primary key
#  amount             :decimal(10, 2)
#  billing_reason     :string
#  currency           :string
#  description        :string
#  hosted_invoice_url :string
#  invoice_pdf        :string
#  paid_at            :datetime
#  status             :string           not null
#  stripe_charge_id   :string
#  stripe_customer_id :string
#  stripe_invoice_id  :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  account_id         :bigint           not null
#
# Indexes
#
#  index_payment_transactions_on_account_id         (account_id)
#  index_payment_transactions_on_stripe_invoice_id  (stripe_invoice_id) UNIQUE
#
class PaymentTransaction < ApplicationRecord
  belongs_to :account

  validates :stripe_invoice_id, uniqueness: true, allow_nil: true

  scope :recent_first, -> { order(paid_at: :desc, created_at: :desc) }
end
