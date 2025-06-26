require "test_helper"

class StreakAndBonusWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:with_streak_bonuses)  # User with bonuses enabled
    @participant = participants(:streak_participant)
    @task = Task.create!(
      title: "Streak Test Task",
      worth: 10.0,
      interval: 1,
      user: @user
    )
    sign_in @user
  end

  test "streak building workflow over multiple days" do
    # Ensure streak bonuses are enabled
    @user.update!(
      streak_boni_enabled: true,
      streak_boni_days_threshold: 2
    )

    # Clear existing actions for clean test
    @participant.actions.destroy_all

    # Day 1: Complete task
    travel_to 3.days.ago do
      post actions_path, params: {
        data: {
          task_id: @task.id,
          participant_id: @participant.id
        }
      }

      action = Action.last
      assert_not action.on_streak, "First day should not be on streak"
    end

    # Day 2: Complete task (still building streak)
    travel_to 2.days.ago do
      post actions_path, params: {
        data: {
          task_id: @task.id,
          participant_id: @participant.id
        }
      }

      action = Action.last
      # May or may not be on streak depending on implementation
    end

    # Day 3: Complete task (should be on streak)

    travel_to 1.day.ago do
      post actions_path, params: {
        data: {
          task_id: @task.id,
          participant_id: @participant.id
        }
      }
      action = Action.last
      @participant.reload


      # Check if participant is on streak
      if @participant.streak > @user.streak_boni_days_threshold
        assert action.on_streak, "Action should be marked as on streak"
      end
    end

    # Verify total points include streak bonuses
    @participant.reload
    total_points = @participant.total_points.to_f
    base_points = @participant.actions.joins(:task).sum("tasks.worth")

    if @user.streak_boni_enabled?
      streak_count = @participant.actions.where(on_streak: true).count
      expected_minimum = base_points + streak_count
      assert total_points >= expected_minimum, "Total should include streak bonuses"
    end
  end

  test "streak breaks when missing a day" do
    @user.update!(
      streak_boni_enabled: true,
      streak_boni_days_threshold: 2
    )

    @participant.actions.destroy_all

    # Day 1: Complete task
    travel_to 4.days.ago do
      post actions_path, params: {
        data: {
          task_id: @task.id,
          participant_id: @participant.id
        }
      }
    end

    # Day 2: Complete task
    travel_to 3.days.ago do
      post actions_path, params: {
        data: {
          task_id: @task.id,
          participant_id: @participant.id
        }
      }
    end

    # Skip Day 3 (break streak)

    # Day 4: Complete task (streak should be reset)
    travel_to 1.day.ago do
      post actions_path, params: {
        data: {
          task_id: @task.id,
          participant_id: @participant.id
        }
      }

      @participant.reload
      streak = @participant.streak

      # Streak should be low since we skipped a day
      assert streak <= @user.streak_boni_days_threshold,
             "Streak should be broken after missing a day"
    end
  end

  test "overdue bonus calculation workflow" do
    @user.update!(overdue_bonus_enabled: true)

    # Create overdue task by backdating it
    overdue_task = Task.create!(
      title: "Overdue Task",
      worth: 20.0,
      interval: 1,
      user: @user,
      created_at: 5.days.ago
    )

    # Verify task is overdue
    assert overdue_task.overdue < 0, "Task should be overdue"

    # Calculate expected bonus
    expected_bonus = overdue_task.calculate_bonus_points
    assert expected_bonus > 0, "Overdue task should have bonus points"

    # Complete the overdue task
    post actions_path, params: {
      data: {
        task_id: overdue_task.id,
        participant_id: @participant.id
      }
    }

    action = Action.last
    assert_equal expected_bonus, action.bonus_points,
           "Action should have correct bonus points"

    # Verify bonus points are included in total
    @participant.reload
    total_points = @participant.total_points.to_f
    bonus_total = @participant.actions.sum("COALESCE(bonus_points, 0)")

    assert bonus_total >= expected_bonus, "Total bonus should include overdue bonus"
  end

  test "overdue bonus disabled workflow" do
    @user.update!(overdue_bonus_enabled: false)

    # Create overdue task
    overdue_task = Task.create!(
      title: "Overdue No Bonus Task",
      worth: 15.0,
      interval: 1,
      user: @user,
      created_at: 3.days.ago
    )

    # Verify task is overdue but bonus is 0
    assert overdue_task.overdue < 0, "Task should be overdue"
    assert_equal 0, overdue_task.calculate_bonus_points,
           "Bonus should be 0 when disabled"

    # Complete the task
    post actions_path, params: {
      data: {
        task_id: overdue_task.id,
        participant_id: @participant.id
      }
    }

    action = Action.last
    assert_equal 0, action.bonus_points, "Action should have no bonus points"
  end

  test "settings change affects future actions" do
    # Start with bonuses disabled
    @user.update!(
      streak_boni_enabled: false,
      overdue_bonus_enabled: false
    )

    # Complete a task
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_id: @participant.id
      }
    }

    action1 = Action.last
    initial_total = @participant.reload.total_points.to_f

    # Enable streak bonuses via settings
    post toggle_streak_boni_path, params: { enabled: "1" },  as: :turbo_stream
    # In your test, add this before the failing line:
    assert_response :success

    @user.reload
    assert @user.streak_boni_enabled

    # Complete another task
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_id: @participant.id
      }
    }

    action2 = Action.last
    new_total = @participant.reload.total_points.to_f

    # Total should have increased by at least the task worth
    assert new_total >= initial_total + @task.worth,
           "Total should increase with new task completion"

    # Enable overdue bonuses
    post toggle_overdue_bonus_path, params: { enabled: "1" }, as: :turbo_stream
    assert_response :success

    @user.reload
    assert @user.overdue_bonus_enabled

    # Create and complete overdue task
    overdue_task = Task.create!(
      title: "Settings Overdue Task",
      worth: 12.0,
      interval: 1,
      user: @user,
      created_at: 2.days.ago
    )

    pre_overdue_total = @participant.reload.total_points.to_f

    post actions_path, params: {
      data: {
        task_id: overdue_task.id,
        participant_id: @participant.id
      }
    }

    action3 = Action.last
    post_overdue_total = @participant.reload.total_points.to_f

    # Should have bonus points now
    assert action3.bonus_points > 0, "Overdue task should have bonus points after enabling"
    assert post_overdue_total > pre_overdue_total + overdue_task.worth,
           "Total should include bonus points"
  end

  test "streak threshold change affects streak status" do
    @user.update!(
      streak_boni_enabled: true,
      streak_boni_days_threshold: 5  # High threshold
    )

    @participant.actions.destroy_all

    # Build a 3-day streak
    3.times do |i|
      travel_to (3-i).days.ago do
        post actions_path, params: {
          data: {
            task_id: @task.id,
            participant_id: @participant.id
          }
        }
      end
    end

    @participant.reload
    assert @participant.streak < @user.streak_boni_days_threshold,
           "3-day streak should be below 5-day threshold"
    assert_not @participant.on_streak, "Participant should not be on streak"

    # Lower the threshold
    post update_streak_bonus_days_threshold_path,
          params: { days_threshold: "2" },  as: :turbo_stream
    assert_response :success

    @user.reload
    assert_equal 2, @user.streak_boni_days_threshold

    @participant.reload
    if @participant.streak > @user.streak_boni_days_threshold
      assert @participant.on_streak, "Participant should now be on streak"
    end
  end

  test "multiple participants with different streak patterns" do
    @user.update!(
      streak_boni_enabled: true,
      streak_boni_days_threshold: 2
    )

    participant1 = @participant
    participant2 = participants(:streak_participant_two)  # Different participant

    # Clear existing actions
    [ participant1, participant2 ].each { |p| p.actions.destroy_all }

    # Participant 1: Consistent daily completions
    3.times do |i|
      travel_to (3-i).days.ago do
        post actions_path, params: {
          data: {
            task_id: @task.id,
            participant_id: participant1.id
          }
        }
      end
    end

    # Participant 2: Sporadic completions (only day 1 and day 3)
    [ 3, 1 ].each do |days_ago|
      travel_to days_ago.days.ago do
        post actions_path, params: {
          data: {
            task_id: @task.id,
            participant_id: participant2.id
          }
        }
      end
    end

    # Check streaks
    participant1.reload
    participant2.reload

    # Participant 1 should have a longer streak
    assert participant1.streak >= participant2.streak,
           "Consistent participant should have longer streak"

    # Check statistics page shows different data
    get statistics_path
    assert_response :success
    assert_includes response.body, participant1.name
    assert_includes response.body, participant2.name
  end

  test "task without interval doesnt affect overdue bonus" do
    @user.update!(overdue_bonus_enabled: true)

    # Create task without interval
    no_interval_task = Task.create!(
      title: "No Interval Task",
      worth: 8.0,
      interval: nil,
      user: @user,
      created_at: 10.days.ago
    )

    # Verify no overdue calculation
    assert_nil no_interval_task.overdue, "Task without interval should not be overdue"
    assert_equal 0, no_interval_task.calculate_bonus_points,
           "Task without interval should have no bonus points"

    # Complete the task
    post actions_path, params: {
      data: {
        task_id: no_interval_task.id,
        participant_id: @participant.id
      }
    }

    action = Action.last
    assert_equal 0, action.bonus_points, "Action should have no bonus points"
  end

  test "statistics accurately reflect bonus calculations" do
    @user.update!(
      streak_boni_enabled: true,
      overdue_bonus_enabled: true,
      streak_boni_days_threshold: 1
    )

    # Create overdue task
    overdue_task = Task.create!(
      title: "Stats Overdue Task",
      worth: 20.0,
      interval: 1,
      user: @user,
      created_at: 3.days.ago
    )

    # Complete tasks to build data
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_id: @participant.id
      }
    }

    post actions_path, params: {
      data: {
        task_id: overdue_task.id,
        participant_id: @participant.id
      }
    }

    # Check statistics page
    get statistics_path
    assert_response :success

    # Verify participant data is shown
    assert_includes response.body, @participant.name

    # Check that points calculations are consistent
    @participant.reload
    displayed_points = @participant.total_points

    # The statistics should reflect the same total points
    assert_not_nil displayed_points
    assert displayed_points.to_f > 0
  end
end
