require "test_helper"

class HouseholdsControllerUnitTest < ActionController::TestCase
  tests HouseholdsController
  
  setup do
    @user_two = users(:two)
    @household_one = households(:one) 
    @household_two = households(:two)
    
    # Mock current_user by setting session
    session[:user_id] = @user_two.id
    session[:firebase_uid] = @user_two.firebase_uid
  end
  
  test "should switch household and update current_household" do
    # Set initial household
    @user_two.set_current_household(@household_one)
    
    # Verify initial state
    assert_equal @household_one, @user_two.current_household
    
    # Switch to household_two
    patch :switch_household, params: { id: @household_two.id }
    
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

  test "should create household with default tasks" do
    initial_household_count = Household.count
    initial_task_count = Task.count
    
    post :create, params: { 
      household: { 
        name: "Test Household with Tasks", 
        description: "Testing default tasks creation" 
      } 
    }
    
    # Verify household was created
    assert_equal initial_household_count + 1, Household.count
    assert_response :redirect
    assert_equal "Household was successfully created.", flash[:notice]
    
    # Verify default tasks were created
    new_household = Household.last
    assert_equal 8, new_household.tasks.count, "Should create 8 default tasks"
    
    # Verify some specific tasks
    tasks = new_household.tasks.ordered
    assert_equal "Dishes", tasks.first.title
    assert_equal 1, tasks.first.worth
    assert_nil tasks.first.interval
    assert_not tasks.first.archived
    
    assert_equal "Take out trash", tasks.second.title
    assert_equal 1, tasks.second.worth
    assert_equal 3, tasks.second.interval
    
    # Verify user membership
    membership = @user_two.household_memberships.find_by(household: new_household)
    assert membership
    assert_equal "owner", membership.role
    assert membership.current_household
  end
end