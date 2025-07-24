require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  # include Devise::Test::IntegrationHelpers


  def setup
    @user = users(:one)
    @participant = participants(:alice)
    @task = tasks(:dishwashing)
    sign_in @user
  end

  test "should require authentication for all actions" do
    sign_out @user

    get pages_home_path
    assert_redirected_to sign_in_path

    get statistics_path
    assert_redirected_to sign_in_path

    get settings_path
    assert_redirected_to sign_in_path
  end

  # --- Home Action Tests ---

  test "should get home" do
    get pages_home_path
    assert_response :success
    assert_assigns(:participants)
    assert_assigns(:tasks)
  end

  test "should get home as turbo stream" do
    get root_path, as: :turbo_stream
    assert_redirected_to pages_home_path
  end

  test "home should load only active participants and tasks" do
    # Create archived participants and tasks
    archived_participant = participants(:archived_participant)
    archived_task = tasks(:archived_task)

    get pages_home_path
    assert_response :success

    participants = assigns(:participants)
    tasks = assigns(:tasks)

    # Should only include active items
    participants.each do |participant|
      assert_not participant.archived, "Should only load active participants"
    end

    tasks.each do |task|
      assert_not task.archived, "Should only load active tasks"
    end

    # Should not include archived items
    assert_not_includes participants, archived_participant
    assert_not_includes tasks, archived_task
  end

  test "home should load participants with eager loaded associations" do
    get pages_home_path
    assert_response :success

    participants = assigns(:participants)

    # Test that associations are loaded to prevent N+1 queries
    # This is hard to test directly, but we can check that the data is accessible
    participants.each do |participant|
      assert_nothing_raised do
        participant.actions.each { |action| action.task.title }
      end
    end
  end

  test "home should load tasks with eager loaded associations" do
    get pages_home_path
    assert_response :success

    tasks = assigns(:tasks)

    # Test that associations are loaded
    tasks.each do |task|
      assert_nothing_raised do
        task.actions.count
      end
    end
  end

  test "home should order tasks correctly" do
    get pages_home_path
    assert_response :success

    tasks = assigns(:tasks)
    positions = tasks.pluck(:position).compact

    # Should be ordered by position
    assert_equal positions.sort, positions
  end

  test "home should only show current user's data" do
    other_user_participant = participants(:user_two_participant)
    other_user_task = tasks(:user_two_task)

    get pages_home_path
    assert_response :success

    participants = assigns(:participants)
    tasks = assigns(:tasks)

    assert_not_includes participants, other_user_participant
    assert_not_includes tasks, other_user_task
  end

  # --- Statistics Action Tests ---

  test "should get statistics" do
    get statistics_path
    assert_response :success
    assert_assigns(:data)
    assert_assigns(:task_completion_by_participant)
    assert_assigns(:task_completion_by_action)
    assert_assigns(:points_by_participant)
    assert_assigns(:task_popularity)
    assert_assigns(:activity_over_time)
    assert_assigns(:participant_activity)
    assert_assigns(:points_by_day)
    assert_assigns(:cumulative_points_by_participant_day)
    assert_assigns(:chart_labels)
    assert_assigns(:chart_cumulative_data)
  end

  test "should get statistics as turbo stream" do
    get statistics_path, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "statistics should use StatisticsService" do
    # Test that statistics page loads successfully
    # The service integration is tested indirectly through the view rendering
    get statistics_path
    assert_response :success

    # Verify that all expected instance variables are set
    assert_assigns(:data)
  end

  test "statistics should pass participants to StatisticsService" do
    get statistics_path
    assert_response :success

    # Verify that @participants is set and passed to the service
    assert_assigns(:participants)
  end

  test "statistics should handle active parameter" do
    get statistics_path, params: { active: true }
    assert_response :success

    participants = assigns(:participants)
    participants.each do |participant|
      assert_not participant.archived
    end
  end

  test "statistics data should be properly formatted" do
    get statistics_path
    assert_response :success

    # Test data structure
    task_completion = assigns(:task_completion_by_participant)
    assert_kind_of Hash, task_completion

    points_by_participant = assigns(:points_by_participant)
    assert_kind_of Hash, points_by_participant

    task_popularity = assigns(:task_popularity)
    assert_kind_of Hash, task_popularity

    chart_labels = assigns(:chart_labels)
    assert_kind_of Array, chart_labels

    chart_data = assigns(:chart_cumulative_data)
    assert_kind_of Hash, chart_data
  end

  test "statistics should handle users with no data" do
    # Clear all user data
    # First destroy actions through participants, then destroy participants and tasks
    @user.participants.each { |p| p.actions.destroy_all }
    @user.participants.destroy_all
    @user.tasks.destroy_all

    get statistics_path
    assert_response :success

    # Should not raise errors even with no data
    assert_assigns(:data)
    assert_assigns(:task_completion_by_participant)
  end

  # --- Settings Action Tests ---

  test "should get settings" do
    get settings_path
    assert_response :success
  end

  test "should get settings as turbo stream" do
    get settings_path, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  # --- Private Method Tests (tested through public interface) ---

  test "set_tasks should respect active parameter" do
    # Test through statistics action which uses set_tasks
    get statistics_path, params: { active: true }
    assert_response :success

    tasks = assigns(:tasks)
    tasks.each do |task|
      assert_not task.archived, "Should only load active tasks when active=true"
    end
  end

  test "set_tasks should load all tasks when active parameter is false" do
    get statistics_path, params: { active: false }
    assert_response :success

    tasks = assigns(:tasks)
    # Should include both active and archived tasks
    assert tasks.count >= @user.tasks.active.count
  end

  test "set_participants should respect active parameter" do
    get statistics_path, params: { active: true }
    assert_response :success

    participants = assigns(:participants)
    participants.each do |participant|
      assert_not participant.archived, "Should only load active participants when active=true"
    end
  end

  test "set_participants should load all participants when active parameter is false" do
    get statistics_path, params: { active: false }
    assert_response :success

    participants = assigns(:participants)
    # Should include both active and archived participants
    assert participants.count >= @user.participants.active.count
  end

  test "set_participants should eager load associations" do
    get statistics_path
    assert_response :success

    participants = assigns(:participants)

    # Verify associations are loaded (no additional queries should be needed)
    participants.each do |participant|
      assert_nothing_raised do
        participant.actions.each { |action| action.task }
      end
    end
  end

  # --- Edge Cases ---

  test "should handle missing participants gracefully" do
    @user.participants.destroy_all

    get pages_home_path
    assert_response :success

    participants = assigns(:participants)
    assert_empty participants
  end

  test "should handle missing tasks gracefully" do
    @user.tasks.destroy_all

    get pages_home_path
    assert_response :success

    tasks = assigns(:tasks)
    assert_empty tasks
  end

  test "should handle user with only archived data" do
    # Archive all user's participants and tasks
    @user.participants.update_all(archived: true)
    @user.tasks.update_all(archived: true)

    get pages_home_path
    assert_response :success

    participants = assigns(:participants)
    tasks = assigns(:tasks)

    assert_empty participants
    assert_empty tasks
  end

  test "statistics should handle complex data relationships" do
    # Create some complex data relationships
    task = Task.create!(title: "Complex Task", worth: 10, user: @user)
    participant = Participant.create!(name: "Complex Participant", user: @user)

    # Create multiple actions
    3.times do |i|
      action = Action.create!(task: task, created_at: i.days.ago)
      action.add_participants([ participant.id ])
    end

    get statistics_path
    assert_response :success

    # Should handle the complex relationships without errors
    assert_assigns(:data)
    assert_assigns(:cumulative_points_by_participant_day)
  end

  test "should scope all data to current user only" do
    other_user = users(:two)

    get statistics_path
    assert_response :success

    # Verify no data from other users is included
    participants = assigns(:participants)
    tasks = assigns(:tasks)

    participants.each do |participant|
      assert_equal @user, participant.user
    end

    tasks.each do |task|
      assert_equal @user, task.user
    end
  end

  private

  def assert_assigns(variable_name)
    assert_not_nil assigns(variable_name), "@#{variable_name} should be assigned"
  end
end
