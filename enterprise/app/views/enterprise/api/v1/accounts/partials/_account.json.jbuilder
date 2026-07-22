json.subscribed_features @account.subscribed_features

plan_name = @account.custom_attributes['plan_name'].to_s.downcase

if plan_name == 'enterprise'
  contract = EnterpriseContract.find_by(account_id: @account.id)
  if contract
    is_active = contract.contract_end_date >= Time.zone.today
    json.subscription do
      json.status is_active ? 'active' : 'expired'
      json.plan_name 'Enterprise'
      json.active is_active
    end
  else
    json.subscription nil
  end
elsif @account.subscription.present?
  json.subscription do
    json.status @account.subscription.status
    json.plan_name @account.subscription.plan_name
    json.active @account.subscription.active?
  end
else
  json.subscription nil
end
