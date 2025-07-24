require "test_helper"

class HouseholdMembershipTest < ActiveSupport::TestCase
  test "should create membership with valid attributes" do
    household = households(:one)
    user = users(:two)
    
    membership = HouseholdMembership.new(
      user: user,
      household: household,
      role: 'member'
    )
    
    assert membership.valid?
    assert membership.save
  end

  test "should require valid role" do
    membership = HouseholdMembership.new(
      user: users(:one),
      household: households(:one),
      role: 'invalid_role'
    )
    
    assert_not membership.valid?
    assert_includes membership.errors[:role], "is not included in the list"
  end

  test "should prevent duplicate user-household combinations" do
    existing = household_memberships(:user_one_household_one_owner)
    
    duplicate = HouseholdMembership.new(
      user: existing.user,
      household: existing.household,
      role: 'member'
    )
    
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:user_id], "has already been taken"
  end

  test "role helper methods should work correctly" do
    owner = household_memberships(:user_one_household_one_owner)
    member = household_memberships(:user_two_household_one_member)
    
    assert owner.owner?
    assert_not owner.member?
    assert owner.can_manage_household?
    
    assert member.member?
    assert_not member.owner?
    assert_not member.can_manage_household?
  end
end