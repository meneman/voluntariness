require "test_helper"

class HouseholdsControllerTest < ActionDispatch::IntegrationTest
  
  setup do
    @user_one = users(:one)
    @user_two = users(:two)
    @household_one = households(:one)
    @household_two = households(:two)
    
    # Use the sign_in helper method for integration tests
    sign_in @user_two
  end

  test "should get index" do
    get households_path
    assert_response :success
  end

  test "should get show" do
    get household_path(@household_one)
    assert_response :success
  end

  test "should get new" do
    get new_household_path
    assert_response :success
  end

  test "should create household" do
    assert_difference('Household.count') do
      post households_path, params: { household: { name: "New Test Household", description: "Test description" } }
    end
    
    assert_redirected_to Household.last
    assert_equal "Household was successfully created.", flash[:notice]
  end

  test "should get edit" do
    get edit_household_path(@household_two) # user_two owns household_two
    assert_response :success
  end

  test "should update household" do
    patch household_path(@household_two), params: { household: { name: "Updated Name" } }
    assert_redirected_to @household_two
    assert_equal "Household was successfully updated.", flash[:notice]
    @household_two.reload
    assert_equal "Updated Name", @household_two.name
  end

  test "should destroy household" do
    # First create another household for user_two so they have more than one
    household = Household.create!(name: "Extra Household", description: "Extra")
    HouseholdMembership.create!(user: @user_two, household: household, role: "owner", current_household: false)
    
    assert_difference('Household.count', -1) do
      delete household_path(household)
    end
    
    assert_redirected_to households_path
    assert_equal "Household was successfully deleted.", flash[:notice]
  end

  test "should switch household and update current_household" do
    # Initial state: user_two's current household should be household_two (from fixtures)
    # But fixtures show household_two as current_household: false, so let's set it up properly
    @user_two.set_current_household(@household_one) # Start with household_one as current
    
    # Verify initial state
    assert_equal @household_one, @user_two.current_household
    
    # Switch to household_two
    patch switch_household_household_path(@household_two)
    
    # Reload user to get fresh data
    @user_two.reload
    
    # Verify the switch worked
    assert_equal @household_two, @user_two.current_household, "User's current household should be updated to household_two"
    
    # Verify household memberships are updated correctly
    membership_one = @user_two.household_memberships.find_by(household: @household_one)
    membership_two = @user_two.household_memberships.find_by(household: @household_two)
    
    assert_not membership_one.current_household, "Membership for household_one should not be current"
    assert membership_two.current_household, "Membership for household_two should be current"
    
    # Verify response
    assert_response :redirect
    assert_equal "Switched to #{@household_two.name}", flash[:notice]
  end

  test "should handle turbo_stream response for switch household" do
    patch switch_household_household_path(@household_two), headers: { "Accept" => "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
  end

  test "should get join form" do
    get join_households_path
    assert_response :success
  end

  test "should join household with valid invite code" do
    # Create a new user who isn't in any household yet
    new_user = User.create!(email: "newuser@example.com", firebase_uid: "test_firebase_uid_1")
    sign_in new_user
    
    post join_households_path, params: { invite_code: @household_one.invite_code }
    
    assert_redirected_to households_path
    assert_equal "Successfully joined #{@household_one.name}!", flash[:notice]
    
    # Verify membership was created
    assert new_user.households.include?(@household_one)
  end

  test "should reject invalid invite code" do
    new_user = User.create!(email: "newuser2@example.com", firebase_uid: "test_firebase_uid_2")
    sign_in new_user
    
    post join_households_path, params: { invite_code: "INVALID" }
    
    assert_response :success # renders :join template with error
    assert_match "Invalid invite code", response.body
  end
end