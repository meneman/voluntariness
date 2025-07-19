require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @task = tasks(:dishwashing)
    @other_user_task = tasks(:user_two_task)
    sign_in @user
  end

  test "should require authentication for all actions" do
    sign_out @user

    get tasks_path
    assert_redirected_to new_user_session_path

    get task_path(@task)
    assert_redirected_to new_user_session_path

    get new_task_path
    assert_redirected_to new_user_session_path

    post tasks_path, params: { task: { title: "Test", worth: 10 } }
    assert_redirected_to new_user_session_path
  end


  test "should get index as turbo stream" do
    get tasks_path, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end



  test "should get show" do
    get task_path(@task)
    assert_response :success
    assert_includes response.body, @task.title
    assert_assigns(:participants)
  end

  test "should not show other user's task" do
    get task_path(@other_user_task)
    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end

  test "should get new" do
    get new_task_path
    assert_response :success
    assert_assigns(:task)
    assert assigns(:task).new_record?
  end

  test "should get new as turbo stream" do
    get new_task_path, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should create task with valid params" do
    assert_difference("@user.tasks.count", 1) do
      post tasks_path, params: {
        task: {
          title: "New Task",
          worth: 15,
          description: "Test description",
          interval: 3
        }
      }
    end

    assert_redirected_to @user.tasks.last

    new_task = @user.tasks.last
    assert_equal "New Task", new_task.title
    assert_equal 15, new_task.worth
    assert_equal "Test description", new_task.description
    assert_equal 3, new_task.interval
  end

  test "should create task as turbo stream" do
    assert_difference("@user.tasks.count", 1) do
      post tasks_path, params: {
        task: {
          title: "Turbo Task",
          worth: 10
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not create task with invalid params" do
    assert_no_difference("@user.tasks.count") do
      post tasks_path, params: {
        task: {
          title: "",  # Invalid: blank title
          worth: 10
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create task without title" do
    assert_no_difference("@user.tasks.count") do
      post tasks_path, params: {
        task: {
          worth: 10
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create task without worth" do
    assert_no_difference("@user.tasks.count") do
      post tasks_path, params: {
        task: {
          title: "Test Task"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_task_path(@task)
    assert_response :success
    assert_assigns(:task)
    assert_equal @task, assigns(:task)
  end

  test "should not edit other user's task" do
    get edit_task_path(@other_user_task)
    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end

  test "should update task with valid params" do
    patch task_path(@task), params: {
      task: {
        title: "Updated Task",
        worth: 20,
        description: "Updated description"
      }
    }

    assert_redirected_to @task
    @task.reload
    assert_equal "Updated Task", @task.title
    assert_equal 20.0, @task.worth
    assert_equal "Updated description", @task.description
  end

  test "should not update task with invalid params" do
    original_title = @task.title

    patch task_path(@task), params: {
      task: {
        title: "",  # Invalid
        worth: 20
      }
    }

    assert_response :unprocessable_entity
    @task.reload
    assert_equal original_title, @task.title
  end

  test "should not update other user's task" do
    original_title = @other_user_task.title
    patch task_path(@other_user_task), params: {
      task: { title: "Hacked" }
    }

    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]

    @other_user_task.reload
    assert_equal original_title, @other_user_task.title
  end

  test "should archive task" do
    assert_not @task.archived

    patch archive_task_path(@task)
    assert_response :success

    @task.reload
    assert @task.archived
  end

  test "should unarchive task" do
    @task.update!(archived: true)

    patch unarchive_task_path(@task)
    assert_response :success

    @task.reload
    assert_not @task.archived
  end

  test "should archive task as turbo stream" do
    patch archive_task_path(@task), as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not archive other user's task" do
    before = @other_user_task.archived
    patch archive_task_path(@other_user_task)
    @other_user_task.reload
    assert_equal before, @other_user_task.archived
  end

  test "should get cancel" do
    get cancel_task_path
    assert_response :success
  end

  test "should destroy task" do
    assert_difference("@user.tasks.count", -1) do
      delete task_path(@task)
    end

    assert_redirected_to tasks_path
  end

  test "should destroy task as turbo stream" do
    assert_difference("@user.tasks.count", -1) do
      delete task_path(@task), as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not destroy other household's task" do
    other_household_task_count = @other_user_task.household.tasks.count

    delete task_path(@other_user_task)

    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
    assert_equal other_household_task_count, @other_user_task.household.tasks.count
  end

  test "should destroy task and its actions" do
    action = Action.create!(task: @task)
    action.add_participants([participants(:alice).id])
    action_id = action.id

    delete task_path(@task)

    assert_nil Action.find_by(id: action_id)
  end

  test "should handle task positioning" do
    # Test that position parameter is permitted
    post tasks_path, params: {
      task: {
        title: "Positioned Task",
        worth: 10,
        position: 1
      }
    }

    assert_redirected_to @user.tasks.last
    new_task = @user.tasks.last
    assert_equal 1, new_task.position
  end

  test "should handle interval parameter" do
    post tasks_path, params: {
      task: {
        title: "Interval Task",
        worth: 10,
        interval: 7
      }
    }

    assert_redirected_to @user.tasks.last
    new_task = @user.tasks.last
    assert_equal 7, new_task.interval
  end

  test "should handle nil interval parameter" do
    post tasks_path, params: {
      task: {
        title: "No Interval Task",
        worth: 10,
        interval: ""
      }
    }

    assert_redirected_to @user.tasks.last
    new_task = @user.tasks.last
    assert_nil new_task.interval
  end

  test "task params should be properly filtered" do
    # Test that only permitted parameters are allowed
    post tasks_path, params: {
      task: {
        title: "Test Task",
        worth: 10,
        user_id: users(:two).id,  # Should be ignored
        archived: true,           # Should be ignored
        id: 999                   # Should be ignored
      }
    }

    assert_redirected_to Task.last
    new_task = Task.last
    assert_equal @user.current_household, new_task.household  # Should belong to current household
    assert_not new_task.archived       # Should not be archived
  end

  test "should assign participants for show action" do
    get task_path(@task)
    assert_response :success

    participants = assigns(:participants)
    assert_not_nil participants
    assert_equal @user.participants, participants
  end

  test "should assign participants and task for create action" do
    post tasks_path, params: {
      task: {
        title: "New Task",
        worth: 10
      }
    }

    assert_redirected_to @user.tasks.last
    assert_assigns(:task)
    assert_assigns(:participants)
    assert_equal @user.participants, assigns(:participants)
  end

  test "should handle ActiveRecord::RecordNotFound gracefully" do
    # This tests the ApplicationController error handling
    get task_path(999999)  # Non-existent task
    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end

  private

  def assert_assigns(variable_name)
    assert_not_nil assigns(variable_name), "@#{variable_name} should be assigned"
  end
end
