require 'administrate/base_dashboard'

class SubscriptionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    account: Field::BelongsTo,
    stripe_customer_id: Field::String,
    stripe_subscription_id: Field::String,
    status: Field::String,
    relationship_type: Field::String,
    connected_account: Field::BelongsTo,
    application_fee_amount: Field::Number.with_options(decimals: 2),
    stripe_price_id: Field::String,
    stripe_product_id: Field::String,
    plan_name: Field::String,
    subscribed_quantity: Field::Number,
    grace_period_ends_at: Field::DateTime,
    current_period_start: Field::DateTime,
    current_period_end: Field::DateTime,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    id
    account
    plan_name
    status
    relationship_type
    grace_period_ends_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    account
    stripe_customer_id
    stripe_subscription_id
    status
    relationship_type
    connected_account
    application_fee_amount
    stripe_price_id
    stripe_product_id
    plan_name
    subscribed_quantity
    grace_period_ends_at
    current_period_start
    current_period_end
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    status
    plan_name
    grace_period_ends_at
    application_fee_amount
  ].freeze

  def display_resource(subscription)
    "Subscription ##{subscription.id} - #{subscription.plan_name}"
  end
end
