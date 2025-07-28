require "test_helper"

class HouseholdsControllerSimpleTest < ActionDispatch::IntegrationTest
  
  test "should switch household and update current_household" do
    user_two = users(:two)
    household_one = households(:one) 
    household_two = households(:two)
    
    # Sign in the user
    sign_in(user_two)
    
    # Set initial household
    user_two.set_current_household(household_one)
    
    # Verify initial state
    assert_equal household_one, user_two.current_household
    
    # Switch to household_two
    patch switch_household_household_path(household_two)
    
    # Reload user to get fresh data
    user_two.reload
    
    # Verify the switch worked
    assert_equal household_two, user_two.current_household, "User's current household should be updated to household_two"
    
    # Verify household memberships are updated correctly
    membership_one = user_two.household_memberships.find_by(household: household_one)
    membership_two = user_two.household_memberships.find_by(household: household_two)
    
    assert_not membership_one.current_household, "Membership for household_one should not be current"
    assert membership_two.current_household, "Membership for household_two should be current"
    
    # Verify response
    assert_response :redirect
    assert_equal "Switched to #{household_two.name}", flash[:notice]
  end
end