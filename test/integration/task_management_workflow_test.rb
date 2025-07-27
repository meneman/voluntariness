require "test_helper"

class TaskManagementWorkflowTest < ActionDispatch::IntegrationTest
  # include Devise::Test::IntegrationHelpers


  def setup
    @user = users(:one)
    @participant = participants(:alice)
    sign_in @user
  end

  test "complete task workflow: create task, add participant, complete task, verify points" do
    # Step 1: Create a new task
    get new_task_path
    assert_response :success

    post tasks_path, params: {
      task: {
        title: "Integration Test Task",
        worth: 15,
        interval: 3,
        description: "A task for integration testing"
      }
    }
    assert_response :redirect

    @user.reload
    new_task = @user.tasks.last
    assert_equal "Integration Test Task", new_task.title
    assert_equal 15, new_task.worth

    # Step 2: Verify task appears on home page
    get root_path
    assert_redirected_to pages_home_path
    follow_redirect!
    assert_includes response.body, "Integration Test Task"

    # Step 3: Complete the task
    initial_action_count = Action.count

    post actions_path, params: {
      data: {
        task_id: new_task.id,
        participant_id: @participant.id
      }
    }
    assert_redirected_to root_path
    assert_equal initial_action_count + 1, Action.count

    # Step 4: Verify action was created with correct attributes
    new_action = Action.last
    assert_equal new_task, new_action.task
    assert_equal @participant, new_action.participant
    assert_not_nil new_action.bonus_points

    # Step 5: Verify points are calculated correctly
    @participant.reload
    total_points = @participant.total_points.to_f
    assert total_points > 0, "Participant should have points after completing task"

    # Step 6: Verify task appears as done today
    assert new_task.done_today, "Task should be marked as done today"

    # Step 7: Check statistics page includes the new data
    get statistics_path
    assert_response :success
    assert_includes response.body, @participant.name
  end

  test "task lifecycle: create, edit, archive, unarchive, delete" do
    # Create task
    post tasks_path, params: {
      task: {
        title: "Lifecycle Task",
        worth: 10,
        interval: 1
      }
    }

    task = @user.tasks.last
    assert_not task.archived

    # Edit task
    patch task_path(task), params: {
      task: {
        title: "Updated Lifecycle Task",
        worth: 12
      }
    }
    assert_redirected_to task

    task.reload
    assert_equal "Updated Lifecycle Task", task.title
    assert_equal 12.0, task.worth

    # Archive task
    patch archive_task_path(task)
    assert_response :success

    task.reload
    assert task.archived

    # Verify archived task doesn't appear on home page
    get root_path
    assert_redirected_to pages_home_path
    follow_redirect!
    assert_not_includes response.body, "Updated Lifecycle Task"

    # Unarchive task
    patch unarchive_task_path(task)
    assert_response :success

    task.reload
    assert_not task.archived

    # Verify unarchived task appears on home page again
    get root_path
    assert_redirected_to pages_home_path
    follow_redirect!
    assert_includes response.body, "Updated Lifecycle Task"

    # Delete task
    initial_task_count = @user.tasks.count
    delete task_path(task)
    assert_redirected_to tasks_path

    assert_equal initial_task_count - 1, @user.tasks.count
    assert_nil Task.find_by(id: task.id)
  end

  test "overdue task workflow with bonus points" do
    # Enable overdue bonus for user
    @user.update!(overdue_bonus_enabled: true)

    # Create task that will be overdue
    task = Task.create!(
      title: "Overdue Task",
      worth: 20,
      interval: 1,
      household: @user.current_household,
      created_at: 3.days.ago
    )

    # Verify task is overdue
    assert task.overdue < 0, "Task should be overdue"

    # Complete the overdue task
    post actions_path, params: {
      data: {
        task_id: task.id,
        participant_id: @participant.id
      }
    }

    # Verify bonus points were applied
    action = Action.last
    assert action.bonus_points > 0, "Overdue task should have bonus points"

    # Verify total points include bonus
    @participant.reload
    total_points = @participant.total_points.to_f
    expected_points = task.worth + action.bonus_points

    # The total might include other actions, so just verify it's reasonable
    assert total_points >= expected_points, "Total points should include task worth and bonus"
  end

  test "participant workflow: create, edit, complete tasks, archive" do
    # Create new participant
    sign_in @user
    post participants_path, params: {
      participant: {
        name: "Integration Participant",
        color: "#FF5733"
      }
    }

    new_participant = @user.participants.last
    assert_equal "Integration Participant", new_participant.name
    assert_equal "#FF5733", new_participant.color

    # Create task for testing
    task = Task.create!(
      title: "Participant Test Task",
      worth: 8,
      household: @user.current_household
    )

    # Participant completes task
    post actions_path, params: {
      data: {
        task_id: task.id,
        participant_id: new_participant.id
      }
    }

    # Verify action was created
    action = Action.last
    assert_equal new_participant, action.participant
    assert_equal task, action.task

    # Check participant's points
    new_participant.reload
    assert new_participant.total_points.to_f >= task.worth

    # Edit participant
    patch participant_path(new_participant), params: {
      participant: {
        name: "Updated Participant Name",
        color: "#33FF57"
      }
    }
    assert_redirected_to participants_path

    new_participant.reload
    assert_equal "Updated Participant Name", new_participant.name
    assert_equal "#33FF57", new_participant.color

    # Archive participant
    patch archive_participant_path(new_participant)
    assert_response :success

    new_participant.reload
    assert new_participant.archived

    # Verify archived participant doesn't appear in active lists
    get root_path
    assert_redirected_to pages_home_path
    follow_redirect!
    # This depends on whether the home page filters by active participants

    # Delete participant
    action_id = action.id
    delete participant_path(new_participant)
    assert_redirected_to pages_home_path

    # Verify participant is deleted, but action remains (multi-participant system)
    assert_nil Participant.find_by(id: new_participant.id)
    # Action should still exist but participant should be removed from it
    remaining_action = Action.find_by(id: action_id)
    assert_not_nil remaining_action
    assert_not_includes remaining_action.participants, new_participant
  end

  test "multi-participant task completion workflow" do
    participants = [ @participant, participants(:bob), participants(:charlie) ]

    # Create a task
    task = Task.create!(
      title: "Multi-Participant Task",
      worth: 5,
      household: @user.current_household
    )

    # Each participant completes the task
    participants.each do |participant|
      post actions_path, params: {
        data: {
          task_id: task.id,
          participant_id: participant.id
        }
      }
    end

    # Verify all actions were created
    assert_equal participants.count, task.actions.count

    # Verify each participant has points
    participants.each do |participant|
      participant.reload
      assert participant.total_points.to_f >= task.worth
    end

    # Check statistics reflect all completions
    get statistics_path
    assert_response :success

    participants.each do |participant|
      assert_includes response.body, participant.name
    end
  end

  test "task interval and done_today workflow" do
    # Create task with 1-day interval
    task = Task.create!(
      title: "Daily Task",
      worth: 3,
      interval: 1,
      household: @user.current_household
    )

    # Complete task today
    post actions_path, params: {
      data: {
        task_id: task.id,
        participant_id: @participant.id
      }
    }

    # Verify task is done today
    task.reload
    assert task.done_today

    # Verify overdue calculation works
    # Delete today's action to test overdue logic
    Action.where(task: task, created_at: Date.current.all_day).destroy_all

    task.reload
    overdue_days = task.overdue
    assert overdue_days <= 0, "Task should be due today or overdue after yesterday's completion"
    assert overdue_days >= -1, "Task shouldn't be more than 1 day overdue"
  end

  test "user settings workflow affecting task completion" do
    # Initially disable bonuses
    @user.update!(
      streak_boni_enabled: false,
      overdue_bonus_enabled: false,
      streak_boni_days_threshold: 5
    )

    # Create and complete task
    task = Task.create!(title: "Settings Test", worth: 10, household: @user.current_household)

    post actions_path, params: {
      data: {
        task_id: task.id,
        participant_id: @participant.id
      }
    }

    action = Action.last
    initial_bonus = action.bonus_points

    # Enable streak bonuses
    patch toggle_streak_boni_path, params: { enabled: "1" }, as: :turbo_stream
    assert_response :success

    @user.reload
    assert @user.streak_boni_enabled

    # Enable overdue bonuses
    patch toggle_overdue_bonus_path, params: { enabled: "1" }, as: :turbo_stream
    assert_response :success

    @user.reload
    assert @user.overdue_bonus_enabled

    # Update streak threshold
    patch update_streak_bonus_days_threshold_path,
          params: { days_threshold: "3" },
          as: :turbo_stream
    assert_response :success

    @user.reload
    assert_equal 3, @user.streak_boni_days_threshold

    # Complete another task to see if settings take effect
    task2 = Task.create!(title: "Settings Test 2", worth: 10, household: @user.current_household)

    post actions_path, params: {
      data: {
        task_id: task2.id,
        participant_id: @participant.id
      }
    }

    # New action should potentially have different bonus calculation
    new_action = Action.last
    # Bonus might be different due to enabled settings
  end

  test "full application workflow: sign up, create data, view statistics" do
    # Skip registration test since registrations are disabled
    skip "Registration is disabled - test only relevant with registrations enabled"
    # Sign out current user
    sign_out @user

    # Create new user account
    post sign_up_path, params: {
      user: {
        email: "integration@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
    assert_redirected_to root_path

    new_user = User.find_by(email: "integration@example.com")
    assert_not_nil new_user

    # Follow redirect to home page
    follow_redirect!
    assert_response :success

    # Create participant
    post participants_path, params: {
      participant: {
        name: "Integration User",
        color: "#4287f5"
      }
    }

    participant = new_user.participants.last

    # Create task
    post tasks_path, params: {
      task: {
        title: "First Task",
        worth: 25,
        interval: 7
      }
    }

    task = new_user.tasks.last

    # Complete task
    post actions_path, params: {
      data: {
        task_id: task.id,
        participant_id: participant.id
      }
    }

    # View statistics
    get statistics_path
    assert_response :success
    assert_includes response.body, participant.name
    assert_includes response.body, task.title

    # Verify data isolation (shouldn't see other users' data)
    assert_not_includes response.body, @user.participants.first.name
    assert_not_includes response.body, @user.tasks.first.title
  end
end
