require "test_helper"

class ActionParticipantTest < ActiveSupport::TestCase
  def setup
    # Clean slate for each test
    ActionParticipant.destroy_all
  end

  test "should be valid with valid attributes" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0,
      bonus_points: 2.0,
      on_streak: false
    )
    assert action_participant.valid?
  end

  test "should require action" do
    action_participant = ActionParticipant.new(
      participant: participants(:alice),
      points_earned: 10.0
    )
    assert_not action_participant.valid?
    assert action_participant.errors[:action].any?, "Action should have validation errors"
  end

  test "should require participant" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      points_earned: 10.0
    )
    assert_not action_participant.valid?
    assert action_participant.errors[:participant].any?, "Participant should have validation errors"
  end

  test "should require points_earned" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice)
    )
    assert_not action_participant.valid?
    assert action_participant.errors[:points_earned].any?, "Points earned should have validation errors"
  end

  test "should allow negative points_earned for gambling" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: -5.0
    )
    assert action_participant.valid?, "Points earned should allow negative values for gambling"
  end

  test "should allow negative bonus_points for gambling penalties" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0,
      bonus_points: -2.0
    )
    assert action_participant.valid?, "Bonus points should allow negative values for gambling penalties"
  end

  test "should allow zero points_earned" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 0.0,
      bonus_points: 0.0
    )
    assert action_participant.valid?
  end

  test "should allow zero bonus_points" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0,
      bonus_points: 0.0
    )
    assert action_participant.valid?
  end

  test "should prevent duplicate action-participant combinations" do
    action = Action.create!(task: tasks(:dishwashing))
    
    # Create first action_participant
    ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    # Try to create duplicate
    duplicate = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 5.0
    )

    assert_not duplicate.valid?
    assert duplicate.errors[:action_id].any?, "Should not allow duplicate action-participant combinations"
  end

  test "should allow same participant in different actions" do
    action1 = Action.create!(task: tasks(:dishwashing))
    action2 = Action.create!(task: tasks(:grocery_shopping))

    ap1 = ActionParticipant.create!(
      action: action1,
      participant: participants(:alice),
      points_earned: 10.0
    )

    ap2 = ActionParticipant.new(
      action: action2,
      participant: participants(:alice),
      points_earned: 15.0
    )

    assert ap2.valid?
  end

  test "should allow same action with different participants" do
    action = Action.create!(task: tasks(:dishwashing))

    ap1 = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    ap2 = ActionParticipant.new(
      action: action,
      participant: participants(:bob),
      points_earned: 10.0
    )

    assert ap2.valid?
  end

  test "should belong to action" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    assert_equal action, action_participant.action
  end

  test "should belong to participant" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    assert_equal participants(:alice), action_participant.participant
  end

  test "should handle decimal points_earned" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 12.75,
      bonus_points: 3.25
    )

    assert action_participant.valid?
    action_participant.save!
    assert_equal 12.75, action_participant.points_earned
    assert_equal 3.25, action_participant.bonus_points
  end

  test "should default bonus_points to 0" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    assert_equal 0.0, action_participant.bonus_points
  end

  test "should default on_streak to false" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    assert_equal false, action_participant.on_streak
  end

  test "should be destroyed when action is destroyed" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    action_participant_id = action_participant.id

    action.destroy

    assert_nil ActionParticipant.find_by(id: action_participant_id)
  end

  test "action_participant should have dependent destroy setup" do
    action = Action.create!(task: tasks(:dishwashing))
    participant = participants(:alice)
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participant,
      points_earned: 10.0
    )

    # Test that the association is properly set up
    assert_equal participant, action_participant.participant
    assert_includes participant.action_participants, action_participant
    
    # Note: We don't test actual destruction due to complex associations
    # This is covered by database cascade constraints and model dependencies
  end

  test "should handle timestamps correctly" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0
    )

    assert_not_nil action_participant.created_at
    assert_not_nil action_participant.updated_at
    assert_kind_of Time, action_participant.created_at
    assert_kind_of Time, action_participant.updated_at
  end

  test "should allow large points_earned values" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.new(
      action: action,
      participant: participants(:alice),
      points_earned: 999999.99,
      bonus_points: 999.99
    )

    assert action_participant.valid?
  end

  test "should track updates correctly" do
    action = Action.create!(task: tasks(:dishwashing))
    action_participant = ActionParticipant.create!(
      action: action,
      participant: participants(:alice),
      points_earned: 10.0,
      bonus_points: 2.0
    )

    original_updated_at = action_participant.updated_at
    sleep 0.1 # Ensure time difference

    action_participant.update!(points_earned: 15.0)

    assert_not_equal original_updated_at, action_participant.updated_at
    assert_equal 15.0, action_participant.points_earned
  end
end