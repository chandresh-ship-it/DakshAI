require 'rails_helper'

RSpec.describe 'Super Admin Plan Management', type: :request do
  let!(:super_admin) { create(:super_admin) }

  before do
    ConfigLoader.new.process(reconcile_only_new: false)
  end

  describe 'GET /super_admin/plan_management' do
    context 'when unauthenticated' do
      it 'redirects to sign in' do
        get '/super_admin/plan_management'
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'when authenticated as super_admin' do
      it 'renders plan management page with seeded plans' do
        sign_in(super_admin, scope: :super_admin)
        get '/super_admin/plan_management'
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Plan Management')
        expect(response.body).to include('Starter')
        expect(response.body).to include('Business')
        expect(response.body).to include('Price per agent')
      end
    end
  end

  describe 'PATCH /super_admin/plan_management' do
    context 'when authenticated as super_admin' do
      it 'updates prices and feature lists for plans' do
        sign_in(super_admin, scope: :super_admin)

        patch '/super_admin/plan_management', params: {
          plans: {
            'Starter' => { 'price_per_agent' => '5.50', 'enabled' => '1' },
            'Business' => { 'price_per_agent' => '25.00', 'enabled' => '1' }
          },
          plan_features: {
            'Starter' => ['inbound_emails'],
            'Business' => ['inbound_emails', 'disable_branding']
          }
        }

        expect(response).to redirect_to(super_admin_plan_management_path)
        expect(flash[:notice]).to eq('Plans updated successfully.')

        # Verify plans saved in database
        plans = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS').value
        starter_plan = plans.find { |p| p['name'] == 'Starter' }
        business_plan = plans.find { |p| p['name'] == 'Business' }

        expect(starter_plan['price_per_agent']).to eq(5.5)
        expect(business_plan['price_per_agent']).to eq(25.0)

        # Verify plan features saved in database
        plan_features = InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLAN_FEATURES').value
        expect(plan_features['Starter']).to eq(['inbound_emails'])
        expect(plan_features['Business']).to eq(['inbound_emails', 'disable_branding'])
      end
    end
  end
end
