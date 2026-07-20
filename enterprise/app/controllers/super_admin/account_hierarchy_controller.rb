class SuperAdmin::AccountHierarchyController < SuperAdmin::ApplicationController
  def show
    @resellers = Account.where(is_reseller: true).includes(:children).order(:name)
  end
end
