require "test_helper"

class ActionTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    action = Action.new(task: tasks(:dishwashing))
    assert action.valid?
  end

  test "should require task" do
    action = Action.new
    assert_not action.valid?
    assert action.errors[:task].any?, "Task should have validation errors"
  end

  test "should allow creation without participants initially" do
    action = Action.new(task: tasks(:dishwashing))
    assert action.valid?
    action.save!
    assert_equal 0, action.participants.count
  end

  test "should belong to task" do
    action = actions(:alice_dishwashing_today)
    assert_equal tasks(:dishwashing), action.task
  end

  test "should have many participants through action_participants" do
    action = actions(:alice_dishwashing_today)
    assert_respond_to action, :participants
    assert_respond_to action, :action_participants
  end

  test "should support adding participants" do
    action = Action.create!(task: tasks(:dishwashing))
    action.add_participants([participants(:alice).id, participants(:bob).id])
    
    assert_equal 2, action.participants.count
    assert_includes action.participants, participants(:alice)
    assert_includes action.participants, participants(:bob)
  end

  test "backward compatibility - participant method should return first participant" do
    action = actions(:alice_dishwashing_today)
    # This should work due to backward compatibility method
    assert_equal participants(:alice), action.participant
  end

  test "last_five_days scope should return actions from last 5 days" do
    # Clear existing actions and create controlled test data
    Action.destroy_all
    
    # Create actions at different times
    recent_action = Action.create!(
      task: tasks(:dishwashing),
      created_at: 2.days.ago
    )
    
    old_action = Action.create!(
      task: tasks(:dishwashing),
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

  test "should set bonus points when adding participants" do
    task = tasks(:overdue_task)
    participant = participants(:alice)
    
    # Mock the task's calculate_bonus_points method
    expected_bonus = 5.0
    task.define_singleton_method(:calculate_bonus_points) { expected_bonus }
    
    action = Action.create!(task: task)
    action.add_participants([participant.id])
    
    action_participant = action.action_participants.first
    assert_equal expected_bonus, action_participant.bonus_points
  end

  test "add_participants should calculate points and bonuses correctly" do
    task = tasks(:dishwashing)
    participant = participants(:alice)
    
    # Set up participant for streak testing  
    participant.household.users.first.update(streak_boni_enabled: true, streak_boni_days_threshold: 0)
    
    # Clear existing action_participants and create streak conditions
    participant.action_participants.destroy_all
    
    # Create recent actions to establish a streak
    [0, 1, 2].each do |days_ago|
      past_action = Action.create!(
        task: task,
        created_at: days_ago.days.ago.beginning_of_day + 12.hours
      )
      ActionParticipant.create!(
        action: past_action,
        participant: participant,
        points_earned: 10.0
      )
    end
    
    # Mock methods
    expected_bonus = 7.5
    task.define_singleton_method(:calculate_bonus_points) { expected_bonus }
    
    action = Action.create!(task: task)
    action.add_participants([participant.id])
    
    action_participant = action.action_participants.first
    assert_equal task.worth, action_participant.points_earned
    assert_equal expected_bonus, action_participant.bonus_points
    assert_equal true, action_participant.on_streak
  end

  test "should not raise errors during creation" do
    task = tasks(:dishwashing)
    
    action = Action.new(task: task)
    
    assert_nothing_raised do
      action.save!
    end
  end

  test "should not raise errors during destruction" do
    action = actions(:alice_dishwashing_today)
    
    assert_nothing_raised do
      action.destroy
    end
  end

  test "backward compatibility - on_streak should return first participant's streak status" do
    action = Action.create!(task: tasks(:dishwashing))
    participant = participants(:alice)
    
    # Enable streak bonuses and set threshold to 0 so participant will be on streak
    participant.household.users.first.update!(streak_boni_enabled: true, streak_boni_days_threshold: 0)
    
    # Create action_participant - the callback will set on_streak based on participant's streak
    ActionParticipant.create!(
      action: action,
      participant: participant,
      points_earned: 10.0
    )
    
    # Reload the action to pick up the new association
    action.reload
    
    # Check backward compatibility method
    assert_equal participant.on_streak, action.on_streak
  end

  test "backward compatibility - bonus_points should return first participant's bonus" do
    action = Action.create!(task: tasks(:dishwashing))
    participant = participants(:alice)
    
    # Mock calculate_bonus_points
    expected_bonus = 10.5
    action.task.define_singleton_method(:calculate_bonus_points) { expected_bonus }
    
    action.add_participants([participant.id])
    
    # Check backward compatibility method
    assert_equal expected_bonus, action.bonus_points
  end

  test "should handle action without participants gracefully" do
    action = Action.create!(task: tasks(:dishwashing))
    
    # These should not raise errors and return sensible defaults
    assert_nil action.participant
    assert_equal 0, action.bonus_points
    assert_equal false, action.on_streak
  end

  test "should accept positive bonus_points through action_participants" do
    task = tasks(:dishwashing)
    task.define_singleton_method(:calculate_bonus_points) { 10.5 }
    
    action = Action.create!(task: task)
    action.add_participants([participants(:alice).id])
    
    action_participant = action.action_participants.first
    assert_equal 10.5, action_participant.bonus_points
  end

  test "should accept zero bonus_points through action_participants" do
    task = tasks(:dishwashing)
    task.define_singleton_method(:calculate_bonus_points) { 0.0 }
    
    action = Action.create!(task: task)
    action.add_participants([participants(:alice).id])
    
    action_participant = action.action_participants.first
    assert_equal 0.0, action_participant.bonus_points
  end

  test "should track creation time" do
    action = Action.create!(task: tasks(:dishwashing))
    
    assert_not_nil action.created_at
    assert_kind_of Time, action.created_at
  end

  test "should allow participants from different users to be added" do
    # Business logic validation should be handled at controller level
    different_user_task = tasks(:user_two_task)
    same_user_participant = participants(:alice)  # belongs to user :one
    
    action = Action.create!(task: different_user_task)
    
    # At model level, this should be allowed (validation happens in controller)
    assert_nothing_raised do
      action.add_participants([same_user_participant.id])
    end
    
    assert_equal 1, action.participants.count
  end

  test "should be destroyed when task is destroyed" do
    task = tasks(:dishwashing)
    action_count = task.actions.count
    
    # Actions should be destroyed due to foreign key constraint
    assert_difference('Action.count', -action_count) do
      task.destroy
    end
  end

  test "action_participants should be destroyed when action is destroyed" do
    action = Action.create!(task: tasks(:dishwashing))
    participant = participants(:alice)
    
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participant,
      points_earned: 10.0
    )
    
    action_participant_id = action_participant.id
    
    action.destroy
    
    # The action_participant should be gone due to dependent: :destroy
    assert_nil ActionParticipant.find_by(id: action_participant_id)
  end

  test "last_five_days scope should use correct constant" do
    # Test that the scope uses the correct constant from VoluntarinessConstants
    expected_days = VoluntarinessConstants::STREAK_CALCULATION_DAYS
    
    # Create an action exactly at the boundary
    boundary_action = Action.create!(
      task: tasks(:dishwashing),
      created_at: expected_days.days.ago.beginning_of_day
    )
    
    outside_action = Action.create!(
      task: tasks(:dishwashing),
      created_at: (expected_days + 1).days.ago.beginning_of_day
    )
    
    scoped_actions = Action.last_five_days
    
    assert_includes scoped_actions, boundary_action
    assert_not_includes scoped_actions, outside_action
  end

  test "should handle nil bonus_points in action_participants" do
    action = Action.create!(task: tasks(:dishwashing))
    action.add_participants([participants(:alice).id])
    
    # Manually set bonus_points to nil to test handling
    action_participant = action.action_participants.first
    action_participant.update_column(:bonus_points, nil)
    action_participant.reload
    
    # Should not raise error when accessing through backward compatibility
    assert_nothing_raised do
      action.bonus_points
    end
  end

  test "add_participants should prevent duplicate participants" do
    action = Action.create!(task: tasks(:dishwashing))
    participant_id = participants(:alice).id
    
    action.add_participants([participant_id])
    
    # Try to add the same participant again - should raise an error due to unique constraint
    assert_raises(ActiveRecord::RecordInvalid) do
      action.add_participants([participant_id])
    end
  end

  test "add_participants should handle multiple participants correctly" do
    action = Action.create!(task: tasks(:dishwashing))
    participant_ids = [participants(:alice).id, participants(:bob).id, participants(:charlie).id]
    
    action.add_participants(participant_ids)
    
    assert_equal 3, action.action_participants.count
    assert_equal 3, action.participants.count
    
    # Each should have correct points and bonuses
    action.action_participants.each do |ap|
      assert_equal action.task.worth, ap.points_earned
      assert_not_nil ap.bonus_points
      assert_not_nil ap.on_streak
    end
  end
end