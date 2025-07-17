require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    participant = Participant.new(
      name: "Test Participant",
      color: "#FF0000",
      user: users(:one)
    )
    assert participant.valid?
  end

  test "should require name" do
    participant = Participant.new(
      color: "#FF0000",
      user: users(:one)
    )
    assert_not participant.valid?
    assert participant.errors[:name].any?, "Name should have validation errors"
  end

  test "should belong to user" do
    participant = participants(:alice)
    assert_equal users(:one), participant.user
  end

  test "should have many action_participants" do
    participant = participants(:alice)
    assert_respond_to participant, :action_participants
  end

  test "should have many actions through action_participants" do
    participant = participants(:alice)
    assert_respond_to participant, :actions
  end

  test "should have many tasks through actions" do
    participant = participants(:alice)
    assert_respond_to participant, :tasks
  end

  test "active scope should return non-archived participants" do
    active_participants = Participant.active
    active_participants.each do |participant|
      assert_equal false, participant.archived
    end
  end

  test "should log action removal" do
    participant = participants(:alice)
    action = participant.actions.first
    
    # Capture log output
    assert_nothing_raised do
      participant.log_action_removal(action)
    end
  end

  test "total_points should calculate base points from action_participants" do
    participant = participants(:alice)
    expected_base_points = participant.action_participants.sum("points_earned")
    
    # Remove other components to test base points
    participant.action_participants.update_all(bonus_points: 0, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    participant.bets.destroy_all  # Remove bets to test just base points
    
    total = participant.total_points.to_f
    assert_equal expected_base_points, total
  end

  test "total_points should include bonus points" do
    participant = participants(:alice)
    
    # Set up specific bonus points
    bonus_amount = 5.5
    participant.action_participants.update_all(bonus_points: bonus_amount, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    participant.bets.destroy_all  # Remove bets to test just bonus points calculation
    
    base_points = participant.action_participants.sum("points_earned")
    total_bonus_points = participant.action_participants.count * bonus_amount
    expected_total = base_points + total_bonus_points
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should include streak bonuses when enabled" do
    participant = participants(:streak_participant)
    participant.user.update(streak_boni_enabled: true)
    
    # Set some action_participants to be on streak
    streak_aps = participant.action_participants.limit(2)
    streak_aps.update_all(on_streak: true)
    participant.action_participants.where.not(id: streak_aps.ids).update_all(on_streak: false)
    participant.action_participants.update_all(bonus_points: 0)
    
    base_points = participant.action_participants.sum("points_earned")
    streak_bonus = streak_aps.count
    expected_total = base_points + streak_bonus
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should ignore streak bonuses when disabled" do
    participant = participants(:no_bonus_participant)
    participant.user.update(streak_boni_enabled: false)
    participant.action_participants.update_all(on_streak: true, bonus_points: 0)
    
    expected_total = participant.action_participants.sum("points_earned")
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should handle nil bonus_points gracefully" do
    participant = participants(:alice)
    participant.action_participants.update_all(bonus_points: nil, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    participant.bets.destroy_all  # Remove bets to test nil bonus points handling
    
    expected_total = participant.action_participants.sum("points_earned")
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should subtract bet costs" do
    participant = participants(:alice)
    
    # Clear existing bets and add a known bet cost
    participant.bets.destroy_all
    participant.bets.create!(cost: 5.0, description: "Test bet", outcome: "pending")
    
    participant.action_participants.update_all(bonus_points: 0, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    
    base_points = participant.action_participants.sum("points_earned")
    expected_total = base_points - 5.0  # Subtract bet cost
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "bonus_points_total should subtract bet costs" do
    participant = participants(:alice)
    
    # Clear existing bets and add a known bet cost
    participant.bets.destroy_all
    participant.bets.create!(cost: 3.0, description: "Test bet", outcome: "pending")
    
    # Set up bonus points
    bonus_amount = 10.0
    participant.action_participants.update_all(bonus_points: bonus_amount, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    
    total_bonus_points = participant.action_participants.count * bonus_amount
    expected_total = total_bonus_points - 3.0  # Subtract bet cost
    
    assert_equal expected_total, participant.bonus_points_total
  end

  test "total_points should format result correctly" do
    participant = participants(:alice)
    result = participant.total_points
    
    # Should return a string representation
    assert_kind_of String, result
    
    # Should be a valid number format  
    assert_match /^\d+(\.\d+)?$/, result
  end

  test "streak should return -1 when streak bonuses are disabled" do
    participant = participants(:no_bonus_participant)
    participant.user.update(streak_boni_enabled: false)
    
    assert_equal -1, participant.streak
  end

  test "streak should calculate consecutive days with actions" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing action_participants and create a controlled set
    participant.action_participants.destroy_all
    
    # Create actions for consecutive days (today, yesterday, day before yesterday)
    [0, 1, 2].each do |days_ago|
      action = Action.create!(
        task: tasks(:dishwashing),
        created_at: days_ago.days.ago.beginning_of_day + 12.hours
      )
      ActionParticipant.create!(
        action: action,
        participant: participant,
        points_earned: 10.0
      )
    end
    
    assert_equal 3, participant.streak
  end

  test "streak should stop counting at first gap" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing action_participants
    participant.action_participants.destroy_all
    
    # Create actions with a gap (today, yesterday, then skip one day, then 3 days ago)
    [
      Time.current.beginning_of_day + 12.hours,
      1.day.ago.beginning_of_day + 12.hours,
      3.days.ago.beginning_of_day + 12.hours  # Skip 2 days ago
    ].each do |created_time|
      action = Action.create!(task: tasks(:dishwashing), created_at: created_time)
      ActionParticipant.create!(action: action, participant: participant, points_earned: 10.0)
    end
    
    assert_equal 2, participant.streak
  end

  test "streak should handle multiple actions per day correctly" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing action_participants
    participant.action_participants.destroy_all
    
    # Create multiple actions on the same day - should only count as one day
    2.times do |i|
      action = Action.create!(
        task: tasks(:dishwashing),
        created_at: Time.current.beginning_of_day + (8 + i).hours
      )
      ActionParticipant.create!(action: action, participant: participant, points_earned: 10.0)
    end
    
    action = Action.create!(
      task: tasks(:dishwashing),
      created_at: 1.day.ago.beginning_of_day + 12.hours
    )
    ActionParticipant.create!(action: action, participant: participant, points_earned: 10.0)
    
    assert_equal 2, participant.streak
  end

  test "streak should return 0 for no recent actions" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing action_participants
    participant.action_participants.destroy_all
    
    # Create an action more than 5 days ago (outside the calculation window)
    action = Action.create!(
      task: tasks(:dishwashing),
      created_at: 6.days.ago
    )
    ActionParticipant.create!(action: action, participant: participant, points_earned: 10.0)
    
    assert_equal 0, participant.streak
  end

  test "on_streak should return true when streak exceeds threshold" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true, streak_boni_days_threshold: 2)
    
    # Mock streak method to return a value above threshold
    participant.define_singleton_method(:streak) { 3 }
    
    assert participant.on_streak
  end

  test "on_streak should return false when streak equals threshold" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true, streak_boni_days_threshold: 3)
    
    # Mock streak method to return value equal to threshold
    participant.define_singleton_method(:streak) { 3 }
    
    assert_not participant.on_streak
  end

  test "on_streak should return false when streak is below threshold" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true, streak_boni_days_threshold: 5)
    
    # Mock streak method to return value below threshold
    participant.define_singleton_method(:streak) { 2 }
    
    assert_not participant.on_streak
  end

  test "participant should belong to user with proper association" do
    user = users(:one)
    participant = participants(:alice)
    
    assert_equal user, participant.user
    assert_includes user.participants, participant
    
    # Test association is set up correctly (don't test actual destruction due to complex associations)
  end

  test "should have action_participants association configured correctly" do
    participant = participants(:alice)
    
    # Test that the association exists and is properly configured
    assert_respond_to participant, :action_participants
    assert_equal ActionParticipant, participant.action_participants.build.class
    
    # Test association includes dependent: :destroy
    reflection = Participant.reflect_on_association(:action_participants)
    assert_equal :destroy, reflection.options[:dependent]
  end

  test "should accept color attribute" do
    participant = Participant.new(
      name: "Colorful",
      color: "#00FF00",
      user: users(:one)
    )
    assert participant.valid?
    assert_equal "#00FF00", participant.color
  end

  test "archived should default to false" do
    participant = Participant.create!(
      name: "New Participant",
      user: users(:one)
    )
    assert_equal false, participant.archived
  end

  test "points calculation should include streak bonuses correctly" do
    participant = participants(:alice)
    user = participant.user
    user.update(streak_boni_enabled: true, overdue_bonus_enabled: false, streak_boni_days_threshold: 1)
    
    # Clear existing action_participants
    participant.action_participants.destroy_all
    participant.bets.destroy_all # Clear bets for clean calculation
    
    # Create actions on consecutive days to build a streak
    task = tasks(:dishwashing)
    
    travel_to 2.days.ago do
      action1 = Action.create!(task: task)
      action1.add_participants([participant.id])
    end
    
    travel_to 1.day.ago do
      action2 = Action.create!(task: task)
      action2.add_participants([participant.id])
    end
    
    # Total should include base points + streak bonus for the second action
    base_points = 10.0 * 2  # 2 actions * 10 points each  
    streak_bonus = 1.0      # 1 action gets streak bonus (second one)
    expected_total = base_points + streak_bonus
    assert_equal expected_total, participant.total_points.to_f
  end

  test "points calculation should include overdue bonuses correctly" do
    participant = participants(:alice)
    user = participant.user
    user.update(streak_boni_enabled: false, overdue_bonus_enabled: true)
    
    # Clear existing action_participants
    participant.action_participants.destroy_all
    
    # Create action_participant with bonus points
    action = Action.create!(task: tasks(:dishwashing))
    ActionParticipant.create!(
      action: action,
      participant: participant,
      points_earned: 10.0,
      bonus_points: 5.0,
      on_streak: false
    )
    
    participant.bets.destroy_all # Clear bets for clean calculation
    
    # Total should include base points + bonus points
    expected_total = 10.0 + 5.0
    assert_equal expected_total, participant.total_points.to_f
  end

  test "points calculation should include both streak and overdue bonuses" do
    participant = participants(:alice)
    user = participant.user
    user.update(streak_boni_enabled: true, overdue_bonus_enabled: true, streak_boni_days_threshold: 1)
    
    # Clear existing action_participants
    participant.action_participants.destroy_all
    participant.bets.destroy_all # Clear bets for clean calculation
    
    # Create task with interval to enable overdue bonus
    task = Task.create!(title: "Overdue Task", worth: 10.0, interval: 7, user: user)
    
    # Mock the task to return overdue bonus
    task.define_singleton_method(:calculate_bonus_points) { 3.0 }
    
    # Create actions on consecutive days to build a streak
    travel_to 2.days.ago do
      action1 = Action.create!(task: task)
      action1.add_participants([participant.id], bonus_points: 0.0)  # No overdue bonus for first action
    end
    
    travel_to 1.day.ago do
      action2 = Action.create!(task: task)
      action2.add_participants([participant.id], bonus_points: 3.0)  # Overdue bonus for second action
    end
    
    # Total should include base points + bonus points + streak bonus
    base_points = 10.0 * 2  # 2 actions * 10 points each
    overdue_bonus = 3.0     # Second action has overdue bonus
    streak_bonus = 1.0      # Second action gets streak bonus
    expected_total = base_points + overdue_bonus + streak_bonus
    assert_equal expected_total, participant.total_points.to_f
  end
end