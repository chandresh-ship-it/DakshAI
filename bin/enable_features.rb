# frozen_string_literal: true

# 1. Create the account if not present
account = Account.first || Account.create!(name: 'My Business')

# 2. Create the user if not present
user = User.find_by(email: 'admin@mybusiness.com')
if user.blank?
  user = User.new(email: 'admin@mybusiness.com', name: 'Administrator', password: 'Password123!', type: 'SuperAdmin')
  user.skip_confirmation!
  user.save!
end

# 3. Link the user to the account as an administrator
unless AccountUser.exists?(account_id: account.id, user_id: user.id)
  AccountUser.create!(account_id: account.id, user_id: user.id, role: :administrator)
end

# 4. Enable all standard features (Paid & Free)
feature_names = Featurable::FEATURE_LIST.pluck('name')
account.enable_features!(*feature_names)

# 5. Enable all AI / Captain features
ai_features = {}
Llm::Models.feature_keys.each do |key|
  ai_features[key] = true
end
account.update!(captain_features: ai_features)

puts "SuperAdmin and all features (standard & AI) enabled successfully for account '#{account.name}'!"
