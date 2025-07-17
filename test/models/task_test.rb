require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    task = Task.new(
      title: "Test Task",
      worth: 10,
      user: users(:one)
    )
    assert task.valid?
  end

  test "should require title" do
    task = Task.new(worth: 10, user: users(:one))
    assert_not task.valid?
    assert task.errors[:title].any?, "Title should have validation errors"
  end

  test "should require worth" do
    task = Task.new(title: "Test Task", user: users(:one))
    assert_not task.valid?
    assert task.errors[:worth].any?, "Worth should have validation errors"
  end

  test "should require user" do
    task = Task.new(title: "Test Task", worth: 10)
    assert_not task.valid?
    assert task.errors[:user].any?, "User should have validation errors"
  end

  test "should belong to user" do
    task = tasks(:dishwashing)
    assert_equal users(:one), task.user
  end

  test "should have many actions" do
    task = tasks(:dishwashing)
    assert_respond_to task, :actions
    assert task.actions.count > 0
  end

  test "should use acts_as_list for positioning" do
    assert_respond_to Task, :acts_as_list
  end

  test "active scope should return non-archived tasks" do
    active_tasks = Task.active
    active_tasks.each do |task|
      assert_equal false, task.archived
    end
  end

  test "ordered scope should return tasks ordered by position" do
    ordered_tasks = Task.ordered
    positions = ordered_tasks.pluck(:position).compact
    assert_equal positions.sort, positions
  end

  test "done_today should return true if last action was today" do
    task = tasks(:dishwashing)
    # Create an action for today
    action = Action.create!(task: task, created_at: Time.current)
    action.add_participants([participants(:alice).id])

    assert task.done_today
  end

  test "done_today should return false if last action was not today" do
    task = tasks(:grocery_shopping)
    # The fixture has actions from yesterday, not today
    assert_not task.done_today
  end

  test "done_today should return false if no actions exist" do
    task = Task.create!(
      title: "New Task",
      worth: 5,
      user: users(:one)
    )
    assert_not task.done_today
  end

  test "overdue should return nil if no interval is set" do
    task = tasks(:no_interval_task)
    assert_nil task.overdue
  end

  test "overdue should calculate days from last action when actions exist" do
    task = tasks(:dishwashing)
    last_action = task.actions.last
    expected_overdue_date = last_action.created_at.to_date + task.interval
    expected_days = (expected_overdue_date.to_date - Time.now.to_date).to_i

    assert_equal expected_days, task.overdue
  end

  test "overdue should calculate days from creation when no actions exist" do
    task = Task.create!(
      title: "New Task",
      worth: 10,
      interval: 3,
      user: users(:one),
      created_at: 5.days.ago
    )

    # Should be overdue (created 5 days ago + 3 day interval = should have been due 2 days ago)
    assert task.overdue < 0, "Task should be overdue"
  end



  test "calculate_bonus_points should return 0 if user has overdue bonus disabled" do
    user = users(:no_bonuses)  # Has overdue_bonus_enabled: false
    task = Task.create!(
      title: "Test Task",
      worth: 10,
      interval: 1,
      user: user,
      created_at: 5.days.ago
    )

    assert_equal 0, task.calculate_bonus_points
  end

  test "calculate_bonus_points should return 0 if task has no interval" do
    task = tasks(:no_interval_task)
    assert_equal 0, task.calculate_bonus_points
  end

  test "calculate_bonus_points should return 0 if task is not overdue" do
    task = tasks(:dishwashing)
    # Create a recent action to make it not overdue
    action = Action.create!(task: task, created_at: Time.current)
    action.add_participants([participants(:alice).id])

    assert task.overdue >= 0
    assert_equal 0, task.calculate_bonus_points
  end

  test "calculate_bonus_points should calculate bonus for overdue tasks" do
    user = users(:with_streak_bonuses)  # Has overdue_bonus_enabled: true
    task = Task.create!(
      title: "Overdue Task",
      worth: 20,
      interval: 1,
      user: user,
      created_at: 5.days.ago
    )

    overdue_days = task.overdue.abs
    expected_bonus = (overdue_days * VoluntarinessConstants::OVERDUE_BONUS_MULTIPLIER).round(1)

    assert task.overdue < 0, "Task should be overdue"
    assert_equal expected_bonus, task.calculate_bonus_points
  end

  test "calculate_bonus_points should use correct multiplier from constants" do
    user = users(:with_streak_bonuses)
    task = Task.create!(
      title: "Overdue Task",
      worth: 10,
      interval: 1,
      user: user
    )

    # Make the task 3 days overdue
    action = Action.create!(task: task, created_at: 4.days.ago)
    action.add_participants([participants(:alice).id])

    overdue_days = task.overdue.abs
    expected_bonus = (overdue_days * VoluntarinessConstants::OVERDUE_BONUS_MULTIPLIER).round(1)

    assert_equal expected_bonus, task.calculate_bonus_points
  end

  test "should be destroyed when user is destroyed" do
    user = users(:one)
    task_ids = user.tasks.pluck(:id)

    user.destroy

    task_ids.each do |task_id|
      assert_nil Task.find_by(id: task_id)
    end
  end

  test "should only accept integer values for worth" do
    task = Task.new(
      title: "Integer Task",
      worth: 15,
      user: users(:one)
    )
    assert task.valid?
    # Worth is stored as integer in database
    assert_equal 15, task.worth
    
    # Test that decimal values are invalid
    task.worth = 15.75
    assert_not task.valid?
    assert_includes task.errors[:worth], "must be an integer"
  end

  test "should accept nil interval" do
    task = Task.new(
      title: "No Interval Task",
      worth: 10,
      interval: nil,
      user: users(:one)
    )
    assert task.valid?
    assert_nil task.interval
  end
end
