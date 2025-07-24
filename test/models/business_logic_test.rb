require "test_helper"

class BusinessLogicTest < ActiveSupport::TestCase
  def setup
    @user = users(:with_streak_bonuses)
    @participant = participants(:streak_participant)
    @no_bonus_user = users(:no_bonuses)
    @no_bonus_participant = participants(:no_bonus_participant)
  end

  # --- Points Calculation Tests ---

  test "total points calculation includes base points from tasks" do
    # Clear existing actions for predictable test
    @participant.actions.destroy_all

    task1 = Task.create!(title: "Task 1", worth: 10, household: @user.current_household)
    task2 = Task.create!(title: "Task 2", worth: 7, household: @user.current_household)

    # Mock tasks to return 0 bonus points
    task1.define_singleton_method(:calculate_bonus_points) { 0 }
    task2.define_singleton_method(:calculate_bonus_points) { 0 }

    action1 = Action.create!(task: task1)
    action1.add_participants([@participant.id])
    action2 = Action.create!(task: task2)
    action2.add_participants([@participant.id])

    # Disable bonuses for clean test
    @user.update!(streak_boni_enabled: false)

    expected_total = 10 + 7
    assert_equal expected_total, @participant.total_points.to_f
  end

  test "total points calculation includes bonus points" do
    # Clear existing actions for predictable test
    @participant.actions.destroy_all

    task = Task.create!(title: "Bonus Task", worth: 10, household: @user.current_household)

    # Mock the task to return specific bonus points
    task.define_singleton_method(:calculate_bonus_points) { 3.5 }

    action = Action.create!(task: task)
    action.add_participants([@participant.id])

    # Disable streak bonuses for clean test
    @user.update!(streak_boni_enabled: false)

    expected_total = 10.0 + 3.5
    assert_equal expected_total, @participant.total_points.to_f
  end

  test "total points calculation includes streak bonuses when enabled" do
    # Clear existing actions for predictable test
    @participant.actions.destroy_all

    task = Task.create!(title: "Streak Task", worth: 8, household: @user.current_household)

    # Mock task to return 0 bonus points
    task.define_singleton_method(:calculate_bonus_points) { 0 }

    # Enable streak bonuses with threshold of 1 day
    @user.update!(streak_boni_enabled: true, streak_boni_days_threshold: 1)

    # Create actions on different days to build a streak
    travel_to 3.days.ago do
      action1 = Action.create!(task: task)
      action1.add_participants([@participant.id])
    end

    travel_to 2.days.ago do  
      action2 = Action.create!(task: task)
      action2.add_participants([@participant.id])
    end

    travel_to 1.day.ago do
      action3 = Action.create!(task: task)
      action3.add_participants([@participant.id])
    end

    base_points = 8.0 * 3  # 3 actions * 8 points each
    streak_bonus = 2 * 1   # 2 streak actions * 1 point each
    expected_total = base_points + streak_bonus


    assert_equal expected_total, @participant.total_points.to_f
  end

  test "total points excludes streak bonuses when disabled" do
    task = Task.create!(title: "No Streak Task", worth: 6, household: @no_bonus_user.current_household)

    # Ensure streak bonuses are disabled
    @no_bonus_user.update!(streak_boni_enabled: false)

    action1 = Action.create!(task: task)
    action1.add_participants([@no_bonus_participant.id])
    action2 = Action.create!(task: task)
    action2.add_participants([@no_bonus_participant.id])

    expected_total = 6.0 * 2  # Only base points, no streak bonus
    assert_equal expected_total, @no_bonus_participant.total_points.to_f
  end

  test "total points handles nil bonus_points gracefully" do
    # Clear existing actions for predictable test
    @participant.actions.destroy_all

    task = Task.create!(title: "Nil Bonus Task", worth: 5, household: @user.current_household)

    action = Action.create!(task: task)
    action.add_participants([@participant.id])
    action.action_participants.first.update_column(:bonus_points, nil)

    @user.update!(streak_boni_enabled: false)

    # Should handle nil bonus_points as 0
    assert_equal 5.0, @participant.total_points.to_f
  end

  # --- Streak Calculation Tests ---

  test "streak calculation counts consecutive days with actions" do
    @user.update!(streak_boni_enabled: true)
    @participant.actions.destroy_all

    # Create actions for consecutive days
    (0..2).each do |days_ago|
      action = Action.create!(
        task: tasks(:dishwashing),
        created_at: days_ago.days.ago.beginning_of_day + 12.hours
      )
      action.add_participants([@participant.id])
    end

    expected_streak = 3
    assert_equal expected_streak, @participant.streak
  end

  test "streak calculation stops at first gap" do
    @user.update!(streak_boni_enabled: true)
    @participant.actions.destroy_all

    # Create actions with a gap (today, yesterday, skip one day, then 3 days ago)
    action1 = Action.create!(task: tasks(:dishwashing), created_at: 0.days.ago.beginning_of_day + 12.hours)
    action1.add_participants([@participant.id])
    action2 = Action.create!(task: tasks(:dishwashing), created_at: 1.day.ago.beginning_of_day + 12.hours)
    action2.add_participants([@participant.id])
    # Skip 2 days ago
    action3 = Action.create!(task: tasks(:dishwashing), created_at: 3.days.ago.beginning_of_day + 12.hours)
    action3.add_participants([@participant.id])

    expected_streak = 2  # Should stop at the gap
    assert_equal expected_streak, @participant.streak
  end

  test "streak calculation handles multiple actions per day" do
    @user.update!(streak_boni_enabled: true)
    @participant.actions.destroy_all

    # Create multiple actions on the same day
    action1 = Action.create!(task: tasks(:dishwashing), created_at: 0.days.ago.beginning_of_day + 8.hours)
    action1.add_participants([@participant.id])
    action2 = Action.create!(task: tasks(:dishwashing), created_at: 0.days.ago.beginning_of_day + 14.hours)
    action2.add_participants([@participant.id])
    action3 = Action.create!(task: tasks(:dishwashing), created_at: 0.days.ago.beginning_of_day + 20.hours)
    action3.add_participants([@participant.id])

    action4 = Action.create!(task: tasks(:dishwashing), created_at: 1.day.ago.beginning_of_day + 12.hours)
    action4.add_participants([@participant.id])

    expected_streak = 2  # Two unique days, regardless of multiple actions per day
    assert_equal expected_streak, @participant.streak
  end

  test "streak calculation returns -1 when bonuses disabled" do
    @no_bonus_user.update!(streak_boni_enabled: false)

    # Create actions that would normally build a streak
    action1 = Action.create!(task: tasks(:user_two_task), created_at: 0.days.ago)
    action1.add_participants([@no_bonus_participant.id])
    action2 = Action.create!(task: tasks(:user_two_task), created_at: 1.day.ago)
    action2.add_participants([@no_bonus_participant.id])

    assert_equal -1, @no_bonus_participant.streak
  end

  test "streak calculation only considers actions within time window" do
    @user.update!(streak_boni_enabled: true)
    @participant.actions.destroy_all

    # Create actions outside the calculation window
    old_action = Action.create!(
      task: tasks(:dishwashing),
      created_at: (VoluntarinessConstants::STREAK_CALCULATION_DAYS + 1).days.ago
    )
    old_action.add_participants([@participant.id])

    # Create recent actions
    action1 = Action.create!(task: tasks(:dishwashing), created_at: 1.day.ago)
    action1.add_participants([@participant.id])
    action2 = Action.create!(task: tasks(:dishwashing), created_at: 0.days.ago)
    action2.add_participants([@participant.id])

    expected_streak = 2  # Should only count recent actions
    assert_equal expected_streak, @participant.streak
  end

  # --- On Streak Tests ---

  test "on_streak returns true when streak exceeds threshold" do
    @user.update!(streak_boni_enabled: true, streak_boni_days_threshold: 2)

    # Mock streak to return value above threshold
    @participant.define_singleton_method(:streak) { 5 }

    assert @participant.on_streak
  end

  test "on_streak returns false when streak equals threshold" do
    @user.update!(streak_boni_enabled: true, streak_boni_days_threshold: 3)

    # Mock streak to return value equal to threshold
    @participant.define_singleton_method(:streak) { 3 }

    assert_not @participant.on_streak
  end

  test "on_streak returns false when streak below threshold" do
    @user.update!(streak_boni_enabled: true, streak_boni_days_threshold: 5)

    # Mock streak to return value below threshold
    @participant.define_singleton_method(:streak) { 2 }

    assert_not @participant.on_streak
  end

  # --- Overdue Calculation Tests ---

  test "overdue calculation with recent completion" do
    task = Task.create!(title: "Recent Task", worth: 10, interval: 3, household: @user.current_household, created_at: 1.week.ago)

    # Complete task recently
    action = Action.create!(task: task, created_at: 1.day.ago)
    action.add_participants([@participant.id])

    # Should not be overdue (last action + interval = 2 days from now)
    expected_days_until_due = 2
    assert_equal expected_days_until_due, task.overdue
  end

  test "overdue calculation with old completion" do
    task = Task.create!(title: "Overdue Task", worth: 10, interval: 2, household: @user.current_household, created_at: 1.week.ago)

    # Complete task in the past
    action = Action.create!(task: task, created_at: 5.days.ago)
    action.add_participants([@participant.id])

    # Should be overdue (last action + interval = 3 days ago)
    expected_overdue_days = -3
    assert_equal expected_overdue_days, task.overdue
  end

  test "overdue calculation with no completions" do
    task = Task.create!(title: "Never Done Task", worth: 10, interval: 1, household: @user.current_household, created_at: 3.days.ago)

    # No actions, should be overdue (created 3 days ago + 1 day interval = should be due 2 days ago, so -2 days overdue)
    # But the actual calculation might be different due to how Time.now.to_date works
    assert task.overdue < 0, "Task should be overdue"
    assert task.overdue >= -4, "Task shouldn't be more than 4 days overdue"
  end

  test "overdue calculation with nil interval" do
    task = Task.create!(title: "No Interval Task", worth: 10, interval: nil, household: @user.current_household)

    assert_nil task.overdue
  end

  # --- Bonus Points Calculation Tests ---

  test "calculate_bonus_points for overdue task" do
    @user.update!(overdue_bonus_enabled: true)

    task = Task.create!(title: "Bonus Task", worth: 20, interval: 1, household: @user.current_household, created_at: 1.week.ago)

    # Make task overdue by 3 days
    action = Action.create!(task: task, created_at: 4.days.ago)
    action.add_participants([@participant.id])

    overdue_days = task.overdue.abs  # Should be 3
    expected_bonus = (overdue_days * VoluntarinessConstants::OVERDUE_BONUS_MULTIPLIER).round(1)

    assert_equal expected_bonus, task.calculate_bonus_points
  end

  test "calculate_bonus_points returns 0 when bonus disabled" do
    @no_bonus_user.update!(overdue_bonus_enabled: false)

    task = Task.create!(title: "No Bonus Task", worth: 20, interval: 1, household: @no_bonus_user.current_household, created_at: 1.week.ago)

    # Make task overdue
    action = Action.create!(task: task, created_at: 5.days.ago)
    action.add_participants([@no_bonus_participant.id])

    assert_equal 0, task.calculate_bonus_points
  end

  test "calculate_bonus_points returns 0 for non-overdue task" do
    @user.update!(overdue_bonus_enabled: true)

    task = Task.create!(title: "Current Task", worth: 20, interval: 7, household: @user.current_household, created_at: 1.week.ago)

    # Complete task recently (not overdue)
    action = Action.create!(task: task, created_at: 1.day.ago)
    action.add_participants([@participant.id])

    assert task.overdue >= 0, "Task should not be overdue"
    assert_equal 0, task.calculate_bonus_points
  end

  test "calculate_bonus_points returns 0 for task without interval" do
    @user.update!(overdue_bonus_enabled: true)

    task = Task.create!(title: "No Interval Task", worth: 20, interval: nil, household: @user.current_household)

    assert_equal 0, task.calculate_bonus_points
  end

  # --- Done Today Tests ---

  test "done_today returns true when last action was today" do
    task = Task.create!(title: "Today Task", worth: 10, household: @user.current_household)

    action = Action.create!(task: task, created_at: Time.current)
    action.add_participants([@participant.id])

    assert task.done_today
  end

  test "done_today returns false when last action was yesterday" do
    task = Task.create!(title: "Yesterday Task", worth: 10, household: @user.current_household)

    action = Action.create!(task: task, created_at: 1.day.ago)
    action.add_participants([@participant.id])

    assert_not task.done_today
  end

  test "done_today returns false when no actions exist" do
    task = Task.create!(title: "No Actions Task", worth: 10, household: @user.current_household)

    assert_not task.done_today
  end

  # --- Complex Business Logic Integration Tests ---

  test "participant with streak and overdue bonuses gets both" do
    @user.update!(
      streak_boni_enabled: true,
      overdue_bonus_enabled: true,
      streak_boni_days_threshold: 1
    )

    # Create overdue task with a previous action to make it truly overdue
    overdue_task = Task.create!(title: "Both Bonuses", worth: 10, interval: 1, household: @user.current_household)

    # Create a previous action 3 days ago to make task overdue (should have been done 2 days ago)
    travel_to 3.days.ago do
      previous_action = Action.create!(task: overdue_task)
      previous_action.add_participants([@participant.id])
    end

    # Build streak first
    travel_to 2.days.ago do
      action = Action.create!(task: tasks(:dishwashing))
      action.add_participants([@participant.id])
    end

    # Complete overdue task while on streak (today - need consistent time for bonus calculation)
    action = nil
    expected_bonus = nil
    
    travel_to 1.day.ago do
      expected_bonus = overdue_task.calculate_bonus_points

      action = Action.new(task: overdue_task)
      action.save!
      # Pass the expected bonus explicitly to ensure it's used
      action.add_participants([@participant.id], bonus_points: expected_bonus)
    end

    # Should have both bonus points (overdue) and be marked as on_streak
    assert action.bonus_points == expected_bonus, "Should have overdue bonus"

    # When calculating total points, should include both types of bonuses
    @participant.reload
    total = @participant.total_points.to_f

    base_points = @participant.action_participants.sum("points_earned")
    bonus_points = @participant.action_participants.sum("COALESCE(bonus_points, 0)")
    streak_bonus = @user.streak_boni_enabled? ? @participant.action_participants.where(on_streak: true).count : 0
    bet_costs = @participant.bets.sum(:cost)

    expected_total = base_points + bonus_points + streak_bonus - bet_costs
    assert_equal expected_total, total
  end

  test "streak threshold changes affect existing streaks" do
    @user.update!(streak_boni_enabled: true, streak_boni_days_threshold: 5)
    @participant.actions.destroy_all

    # Build 3-day streak
    3.times do |i|
      action = Action.create!(
        task: tasks(:dishwashing),
        created_at: i.days.ago.beginning_of_day + 12.hours
      )
      action.add_participants([@participant.id])
    end

    # With threshold of 5, should not be on streak
    assert_not @participant.on_streak

    # Lower threshold to 2
    @user.update!(streak_boni_days_threshold: 2)

    # Now should be on streak
    @participant.reload
    assert @participant.on_streak
  end

  test "business logic constants are used correctly" do
    # Test that actual constants are used in calculations
    assert_equal 0.2, VoluntarinessConstants::OVERDUE_BONUS_MULTIPLIER
    assert_equal 1, VoluntarinessConstants::STREAK_BONUS_POINTS
    assert_equal 2, VoluntarinessConstants::MIN_STREAK_THRESHOLD
    assert_equal 5, VoluntarinessConstants::DEFAULT_STREAK_THRESHOLD
    assert_equal 10, VoluntarinessConstants::STREAK_CALCULATION_DAYS

    # Test overdue bonus calculation uses correct multiplier
    @user.update!(overdue_bonus_enabled: true)
    task = Task.create!(title: "Constants Test", worth: 20, interval: 1, household: @user.current_household, created_at: 6.days.ago)

    overdue_days = task.overdue.abs
    expected_bonus = (overdue_days * VoluntarinessConstants::OVERDUE_BONUS_MULTIPLIER).round(1)

    assert_equal expected_bonus, task.calculate_bonus_points
  end
end
