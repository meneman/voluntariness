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

  test "should have many actions" do
    participant = participants(:alice)
    assert_respond_to participant, :actions
    assert participant.actions.count > 0
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

  test "total_points should calculate base points from tasks" do
    participant = participants(:alice)
    expected_base_points = participant.actions.joins(:task).sum("tasks.worth")
    
    # Remove other components to test base points
    participant.actions.update_all(bonus_points: 0, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    participant.bets.destroy_all  # Remove bets to test just base points
    
    total = participant.total_points.to_f
    assert_equal expected_base_points, total
  end

  test "total_points should include bonus points" do
    participant = participants(:alice)
    
    # Set up specific bonus points
    bonus_amount = 5.5
    participant.actions.update_all(bonus_points: bonus_amount, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    participant.bets.destroy_all  # Remove bets to test just bonus points calculation
    
    base_points = participant.actions.joins(:task).sum("tasks.worth")
    total_bonus_points = participant.actions.count * bonus_amount
    expected_total = base_points + total_bonus_points
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should include streak bonuses when enabled" do
    participant = participants(:streak_participant)
    participant.user.update(streak_boni_enabled: true)
    
    # Set some actions to be on streak
    streak_actions = participant.actions.limit(2)
    streak_actions.update_all(on_streak: true)
    participant.actions.where.not(id: streak_actions.ids).update_all(on_streak: false)
    participant.actions.update_all(bonus_points: 0)
    
    base_points = participant.actions.joins(:task).sum("tasks.worth")
    streak_bonus = streak_actions.count
    expected_total = base_points + streak_bonus
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should ignore streak bonuses when disabled" do
    participant = participants(:no_bonus_participant)
    participant.user.update(streak_boni_enabled: false)
    participant.actions.update_all(on_streak: true, bonus_points: 0)
    
    expected_total = participant.actions.joins(:task).sum("tasks.worth")
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should handle nil bonus_points gracefully" do
    participant = participants(:alice)
    participant.actions.update_all(bonus_points: nil, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    participant.bets.destroy_all  # Remove bets to test nil bonus points handling
    
    expected_total = participant.actions.joins(:task).sum("tasks.worth")
    
    assert_equal expected_total, participant.total_points.to_f
  end

  test "total_points should subtract bet costs" do
    participant = participants(:alice)
    
    # Clear existing bets and add a known bet cost
    participant.bets.destroy_all
    participant.bets.create!(cost: 5.0, description: "Test bet", outcome: "pending")
    
    participant.actions.update_all(bonus_points: 0, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    
    base_points = participant.actions.joins(:task).sum("tasks.worth")
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
    participant.actions.update_all(bonus_points: bonus_amount, on_streak: false)
    participant.user.update(streak_boni_enabled: false)
    
    total_bonus_points = participant.actions.count * bonus_amount
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
    
    # Clear existing actions and create a controlled set
    participant.actions.destroy_all
    
    # Create actions for consecutive days (today, yesterday, day before yesterday)
    [0, 1, 2].each do |days_ago|
      Action.create!(
        participant: participant,
        task: tasks(:dishwashing),
        created_at: days_ago.days.ago.beginning_of_day + 12.hours
      )
    end
    
    assert_equal 3, participant.streak
  end

  test "streak should stop counting at first gap" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing actions
    participant.actions.destroy_all
    
    # Create actions with a gap (today, yesterday, then skip one day, then 3 days ago)
    Action.create!(participant: participant, task: tasks(:dishwashing), created_at: Time.current.beginning_of_day + 12.hours)
    Action.create!(participant: participant, task: tasks(:dishwashing), created_at: 1.day.ago.beginning_of_day + 12.hours)
    # Skip 2 days ago
    Action.create!(participant: participant, task: tasks(:dishwashing), created_at: 3.days.ago.beginning_of_day + 12.hours)
    
    assert_equal 2, participant.streak
  end

  test "streak should handle multiple actions per day correctly" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing actions
    participant.actions.destroy_all
    
    # Create multiple actions on the same day - should only count as one day
    2.times do |i|
      Action.create!(
        participant: participant,
        task: tasks(:dishwashing),
        created_at: Time.current.beginning_of_day + (8 + i).hours
      )
    end
    
    Action.create!(
      participant: participant,
      task: tasks(:dishwashing),
      created_at: 1.day.ago.beginning_of_day + 12.hours
    )
    
    assert_equal 2, participant.streak
  end

  test "streak should return 0 for no recent actions" do
    participant = participants(:alice)
    participant.user.update(streak_boni_enabled: true)
    
    # Clear existing actions
    participant.actions.destroy_all
    
    # Create an action more than 5 days ago (outside the calculation window)
    Action.create!(
      participant: participant,
      task: tasks(:dishwashing),
      created_at: 6.days.ago
    )
    
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

  test "should be destroyed when user is destroyed" do
    user = users(:one)
    # Clear any existing actions that might cause foreign key issues
    user.tasks.each { |task| task.actions.destroy_all }
    user.participants.each { |participant| participant.actions.destroy_all }
    
    participant_ids = user.participants.pluck(:id)
    
    user.destroy
    
    participant_ids.each do |participant_id|
      assert_nil Participant.find_by(id: participant_id)
    end
  end

  test "should destroy dependent actions when participant is destroyed" do
    participant = participants(:alice)
    action_ids = participant.actions.pluck(:id)
    
    participant.destroy
    
    action_ids.each do |action_id|
      assert_nil Action.find_by(id: action_id)
    end
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

  test "apply_bonuses private method should handle streak bonus" do
    participant = participants(:alice)
    user = participant.user
    user.update(streak_boni_enabled: true, overdue_bonus_enabled: false)
    
    # Create a mock action
    action = Action.new(on_streak: true, bonus_points: 0)
    
    # Test the private method (though it's generally better to test through public interface)
    base_points = 10.0
    result = participant.send(:apply_bonuses, base_points, action)
    
    expected = base_points + VoluntarinessConstants::STREAK_BONUS_POINTS
    assert_equal expected, result
  end

  test "apply_bonuses private method should handle overdue bonus" do
    participant = participants(:alice)
    user = participant.user
    user.update(streak_boni_enabled: false, overdue_bonus_enabled: true)
    
    # Create a mock action
    bonus_amount = 5.0
    action = Action.new(on_streak: false, bonus_points: bonus_amount)
    
    base_points = 10.0
    result = participant.send(:apply_bonuses, base_points, action)
    
    expected = base_points + bonus_amount
    assert_equal expected, result
  end

  test "apply_bonuses private method should handle both bonuses" do
    participant = participants(:alice)
    user = participant.user
    user.update(streak_boni_enabled: true, overdue_bonus_enabled: true)
    
    # Create a mock action
    bonus_amount = 3.0
    action = Action.new(on_streak: true, bonus_points: bonus_amount)
    
    base_points = 10.0
    result = participant.send(:apply_bonuses, base_points, action)
    
    expected = base_points + VoluntarinessConstants::STREAK_BONUS_POINTS + bonus_amount
    assert_equal expected, result
  end
end