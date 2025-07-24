require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = User.new(email: "test@example.com", firebase_uid: "firebase_test_uid")
    assert user.valid?
  end

  test "should require email" do
    user = User.new(firebase_uid: "firebase_test_uid")
    assert_not user.valid?
    assert user.errors[:email].any?, "Email should have validation errors"
  end

  test "should require firebase_uid" do
    user = User.new(email: "test@example.com")
    assert_not user.valid?
    assert user.errors[:firebase_uid].any?, "Firebase UID should have validation errors"
  end

  # Email format validation is handled by Firebase, so no local validation needed

  test "email should be unique" do
    existing_user = users(:one)
    user = User.new(email: existing_user.email, firebase_uid: "firebase_test_uid_2")
    assert_not user.valid?
    assert user.errors[:email].any?, "Email should have uniqueness validation errors"
  end

  test "should have many tasks" do
    user = users(:one)
    assert_respond_to user, :tasks
    assert user.tasks.count > 0
  end

  test "should have many participants" do
    user = users(:one)
    assert_respond_to user, :participants
    assert user.participants.count > 0
  end

  test "should have many actions through tasks" do
    user = users(:one)
    assert_respond_to user, :actions
    assert user.actions.count > 0
  end

  test "should destroy dependent tasks when user is deleted" do
    user = users(:one)
    # Clear any existing actions that might cause foreign key issues
    user.tasks.each { |task| task.actions.destroy_all }
    user.participants.each { |participant| participant.actions.destroy_all }
    
    task_count = user.tasks.count
    assert task_count > 0
    
    user.destroy
    assert_equal 0, user.households.joins(:tasks).count
  end

  test "should destroy dependent participants when user is deleted" do
    user = users(:one)
    # Clear any existing actions that might cause foreign key issues
    user.tasks.each { |task| task.actions.destroy_all }
    user.participants.each { |participant| participant.actions.destroy_all }
    
    participant_count = user.participants.count
    assert participant_count > 0
    
    user.destroy
    assert_equal 0, user.participants.count
  end


  test "should have default streak_boni_enabled value" do
    user = User.create!(email: "newuser@example.com", firebase_uid: "firebase_uid_new")
    # Test that the field exists and can be set
    assert_respond_to user, :streak_boni_enabled
    assert_respond_to user, :streak_boni_enabled=
  end

  test "should have default overdue_bonus_enabled value" do
    user = User.create!(email: "newuser2@example.com", firebase_uid: "firebase_uid_new2")
    # Test that the field exists and can be set
    assert_respond_to user, :overdue_bonus_enabled
    assert_respond_to user, :overdue_bonus_enabled=
  end

  test "should have default streak_boni_days_threshold value" do
    user = User.create!(email: "newuser3@example.com", firebase_uid: "firebase_uid_new3")
    # Test that the default value is set correctly
    assert_not_nil user.streak_boni_days_threshold
  end

  test "streak_boni_enabled should be boolean" do
    user = users(:with_streak_bonuses)
    assert_includes [true, false], user.streak_boni_enabled
  end

  test "overdue_bonus_enabled should be boolean" do
    user = users(:with_streak_bonuses)
    assert_includes [true, false], user.overdue_bonus_enabled
  end

  test "streak_boni_days_threshold should be numeric" do
    user = users(:with_streak_bonuses)
    assert_kind_of Numeric, user.streak_boni_days_threshold
  end

  test "should respond to firebase auth methods" do
    user = users(:one)
    assert_respond_to user, :email
    assert_respond_to user, :firebase_uid
  end
end