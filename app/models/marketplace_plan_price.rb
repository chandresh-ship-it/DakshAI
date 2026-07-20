class MarketplacePlanPrice < ApplicationRecord
  belongs_to :account

  validates :currency, presence: true
  validates :agency_price, presence: true, numericality: { greater_than: 0 }
  validates :commission_percent, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :platform_fee_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_amount, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  before_validation :calculate_fees, on: :create
  before_create :deactivate_old_prices
  before_create :create_stripe_price

  private

  def calculate_fees
    return if agency_price.blank?

    self.commission_percent ||= CommissionRule.current_percent_for(account)
    self.platform_fee_amount = (agency_price * (commission_percent / 100.0)).round(2)
    self.total_amount = agency_price + platform_fee_amount
  end

  def deactivate_old_prices
    account.marketplace_plan_prices.where(active: true, currency: currency.downcase).update_all(active: false)
  end

  def create_stripe_price
    return if stripe_price_id.present?

    product_name = "Workspace Subscription (#{account.brand_name.presence || account.name})"
    product = Stripe::Product.create({
      name: product_name,
      metadata: {
        reseller_account_id: account.id.to_s
      }
    })

    price = Stripe::Price.create({
      product: product.id,
      unit_amount: (total_amount * 100).to_i,
      currency: currency.downcase,
      recurring: { interval: 'month' },
      metadata: {
        reseller_account_id: account.id.to_s,
        agency_price: agency_price.to_s,
        platform_fee_amount: platform_fee_amount.to_s
      }
    })

    self.stripe_product_id = product.id
    self.stripe_price_id = price.id
  rescue Stripe::StripeError => e
    errors.add(:base, "Stripe API error: #{e.message}")
    throw(:abort)
  end
end
