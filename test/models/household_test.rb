require "test_helper"

class HouseholdTest < ActiveSupport::TestCase
  test "should create household with valid attributes" do
    household = Household.new(
      name: "Test Household",
      description: "A test household"
    )
    
    assert household.valid?
    assert household.save
    assert_not_nil household.invite_code
    assert_equal 12, household.invite_code.length
  end

  test "should require name" do
    household = Household.new(description: "No name")
    assert_not household.valid?
    assert_includes household.errors[:name], "can't be blank"
  end

  test "should generate unique invite codes" do
    household1 = Household.create!(name: "House 1")
    household2 = Household.create!(name: "House 2")
    
    assert_not_equal household1.invite_code, household2.invite_code
  end

  test "should have many users through household_memberships" do
    household = households(:one)
    assert_respond_to household, :users
    assert_respond_to household, :household_memberships
  end

  test "should have many tasks and participants" do
    household = households(:one)
    assert_respond_to household, :tasks
    assert_respond_to household, :participants
    assert_respond_to household, :actions
  end
end