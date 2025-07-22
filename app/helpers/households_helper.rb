module HouseholdsHelper
  def current_household?(household)
    household.household_memberships.find { |m| m.user_id == current_user.id }&.current_household
  end
end
