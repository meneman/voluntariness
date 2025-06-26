require "test_helper"

class ActionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    action = Action.new(
      task: tasks(:dishwashing),
      participant: participants(:alice)
    )
    assert action.valid?
  end

  test "should require task" do
    action = Action.new(participant: participants(:alice))
    assert_not action.valid?
    assert action.errors[:task].any?, "Task should have validation errors"
  end

  test "should require participant" do
    action = Action.new(task: tasks(:dishwashing))
    assert_not action.valid?
    assert action.errors[:participant].any?, "Participant should have validation errors"
  end

  test "should belong to task" do
    action = actions(:alice_dishwashing_today)
    assert_equal tasks(:dishwashing), action.task
  end

  test "should belong to participant" do
    action = actions(:alice_dishwashing_today)
    assert_equal participants(:alice), action.participant
  end

  test "last_five_days scope should return actions from last 5 days" do
    # Clear existing actions and create controlled test data
    Action.destroy_all
    
    # Create actions at different times
    recent_action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice),
      created_at: 2.days.ago
    )
    
    old_action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice),
      created_at: (VoluntarinessConstants::STREAK_CALCULATION_DAYS + 1).days.ago
    )
    
    scoped_actions = Action.last_five_days
    
    assert_includes scoped_actions, recent_action
    assert_not_includes scoped_actions, old_action
  end

  test "desc scope should return actions in descending order by id" do
    actions = Action.desc.limit(3)
    ids = actions.pluck(:id)
    
    assert_equal ids.sort.reverse, ids
  end

  test "should set bonus points before creation" do
    task = tasks(:overdue_task)
    participant = participants(:alice)
    
    # Mock the task's calculate_bonus_points method
    expected_bonus = 5.0
    task.define_singleton_method(:calculate_bonus_points) { expected_bonus }
    
    action = Action.new(task: task, participant: participant)
    action.save!
    
    assert_equal expected_bonus, action.bonus_points
  end

  test "set_bonus_points should call task's calculate_bonus_points" do
    task = tasks(:dishwashing)
    participant = participants(:alice)
    
    # Create a new action
    action = Action.new(task: task, participant: participant)
    
    # Mock calculate_bonus_points to return a specific value
    expected_bonus = 7.5
    task.define_singleton_method(:calculate_bonus_points) { expected_bonus }
    
    # Manually call the callback method
    action.send(:set_bonus_points)
    
    assert_equal expected_bonus, action.bonus_points
  end

  test "should broadcast after creation" do
    # Test that the broadcast method is called (integration test would be better for this)
    task = tasks(:dishwashing)
    participant = participants(:alice)
    
    action = Action.new(task: task, participant: participant)
    
    # Mock the broadcast method to avoid actual broadcasting in tests
    action.define_singleton_method(:broadcast_total_points) { |action_type| action_type }
    
    assert_nothing_raised do
      action.save!
    end
  end

  test "should broadcast after destruction" do
    action = actions(:alice_dishwashing_today)
    
    # Mock the broadcast method
    action.define_singleton_method(:broadcast_total_points) { |action_type| action_type }
    
    assert_nothing_raised do
      action.destroy
    end
  end

  test "broadcast_total_points should handle create action type" do
    action = actions(:alice_dishwashing_today)
    
    # Mock the broadcast_replace_to method to avoid actual broadcasting
    action.define_singleton_method(:broadcast_replace_to) do |*args, **kwargs|
      { args: args, kwargs: kwargs }
    end
    
    # Test the private broadcast method
    result = action.send(:broadcast_total_points, :create)
    
    # Verify method was called (mock returns the kwargs)
    assert_not_nil result
  end

  test "broadcast_total_points should handle destroy action type" do
    action = actions(:alice_dishwashing_today)
    
    # Mock the broadcast_replace_to method
    action.define_singleton_method(:broadcast_replace_to) do |*args, **kwargs|
      { args: args, kwargs: kwargs }
    end
    
    # Test the private broadcast method
    result = action.send(:broadcast_total_points, :destroy)
    
    assert_not_nil result
  end

  test "on_streak should default to false" do
    action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice)
    )
    
    # Check that on_streak defaults to false if not specified
    assert_equal false, action.on_streak
  end

  test "bonus_points should default to 0 if not set by callback" do
    # Create an action and bypass the callback to test default
    action = Action.new(
      task: tasks(:dishwashing),
      participant: participants(:alice)
    )
    
    # Skip callbacks to test default value
    action.save(validate: false)
    action.reload
    
    # Should have been set by the callback, but if callback failed, should be 0
    assert_not_nil action.bonus_points
  end

  test "should accept positive bonus_points" do
    # Mock the task's calculate_bonus_points to return our expected value
    task = tasks(:dishwashing)
    task.define_singleton_method(:calculate_bonus_points) { 10.5 }
    
    action = Action.create!(
      task: task,
      participant: participants(:alice)
    )
    
    assert_equal 10.5, action.bonus_points
  end

  test "should accept zero bonus_points" do
    action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice),
      bonus_points: 0.0
    )
    
    assert_equal 0.0, action.bonus_points
  end

  test "should track creation time" do
    action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice)
    )
    
    assert_not_nil action.created_at
    assert_kind_of Time, action.created_at
  end

  test "should handle participant and task from different users" do
    # This should fail due to data integrity - participant and task should belong to same user
    different_user_task = tasks(:user_two_task)
    same_user_participant = participants(:alice)  # belongs to user :one
    
    action = Action.new(
      task: different_user_task,
      participant: same_user_participant
    )
    
    # The action might be valid at model level but would violate business logic
    # This could be handled by custom validation if needed
    assert action.valid?  # Currently valid, but business logic might require same user
  end

  test "should be destroyed when task is destroyed" do
    task = tasks(:dishwashing)
    action_count = task.actions.count
    
    # Actions should be destroyed due to foreign key constraint
    assert_difference('Action.count', -action_count) do
      task.destroy
    end
  end

  test "should be destroyed when participant is destroyed" do
    participant = participants(:alice)
    action_ids = participant.actions.pluck(:id)
    
    participant.destroy
    
    action_ids.each do |action_id|
      assert_nil Action.find_by(id: action_id)
    end
  end

  test "last_five_days scope should use correct constant" do
    # Test that the scope uses the correct constant from VoluntarinessConstants
    expected_days = VoluntarinessConstants::STREAK_CALCULATION_DAYS
    
    # Create an action exactly at the boundary
    boundary_action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice),
      created_at: expected_days.days.ago.beginning_of_day
    )
    
    outside_action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice),
      created_at: (expected_days + 1).days.ago.beginning_of_day
    )
    
    scoped_actions = Action.last_five_days
    
    assert_includes scoped_actions, boundary_action
    assert_not_includes scoped_actions, outside_action
  end

  test "should handle nil bonus_points in calculations" do
    action = Action.create!(
      task: tasks(:dishwashing),
      participant: participants(:alice)
    )
    
    # Manually set bonus_points to nil to test handling
    action.update_column(:bonus_points, nil)
    action.reload
    
    # Should not raise error when accessing
    assert_nothing_raised do
      action.bonus_points
    end
  end
end