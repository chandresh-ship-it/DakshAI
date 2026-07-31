namespace :conversation_tabs do
  desc 'Seed ≥10 conversations for All / Mine / Unassigned / Mentions / Teams tabs (ACCOUNT_ID required)'
  task seed: :environment do
    account_id = ENV.fetch('ACCOUNT_ID', nil)
    if account_id.blank?
      puts 'Usage: ACCOUNT_ID=1 bundle exec rake conversation_tabs:seed'
      puts 'Optional: USER_EMAIL=admin@example.com'
      exit 1
    end

    account = Account.find(account_id)
    user = ENV['USER_EMAIL'].present? ? User.from_email(ENV.fetch('USER_EMAIL')) : nil

    Seeders::ConversationTabsSeeder.new(account: account, user: user).perform!
  end
end
