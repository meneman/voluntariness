require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
  end

  # --- Authentication Tests ---

  test "should require authentication for protected actions" do
    # Test that unauthenticated users can access landing page
    get root_path
    assert_response :success
    # Test that protected pages require authentication
    get pages_home_path
    assert_redirected_to new_user_session_path
  end

  test "should allow access when authenticated" do
    sign_in @user
    get root_path
    assert_redirected_to pages_home_path # Landing page redirects authenticated users to home
  end

  # --- Error Handling Tests ---

  test "should handle ActiveRecord::RecordNotFound with redirect" do
    sign_in @user

    # Try to access a non-existent task
    get task_path(999999)

    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end


  # --- Sign-in Redirect Tests ---

  test "after_sign_in_path_for should redirect to home" do
    # Test the custom sign-in redirect
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to pages_home_path
  end

  # --- Browser Compatibility Tests ---

  test "should allow modern browsers" do
    sign_in @user

    # Set a modern user agent
    get root_path, headers: {
      "User-Agent" => "Mozilla/5.0 (Chrome/91.0.4472.124)"
    }

    assert_redirected_to pages_home_path
  end

  # --- Pagy Integration Tests ---

  test "should include Pagy::Backend" do
    assert ApplicationController.included_modules.include?(Pagy::Backend)
  end

  test "should handle pagination in controllers that use it" do
    sign_in @user

    # Create multiple actions for pagination testing
    15.times do |i|
      action = Action.create!(
        task: tasks(:dishwashing),
        created_at: i.hours.ago
      )
      action.add_participants([ participants(:alice).id ])
    end

    get actions_path
    assert_response :success
    assert_assigns(:pagy)
  end

  # --- Integration Tests for Error Handlers ---

  test "not_found should redirect with alert" do
    sign_in @user

    # Create a controller that triggers RecordNotFound
    get task_path(999999)

    assert_redirected_to pages_home_path
    follow_redirect!
    assert_includes response.body, "Resource not found"
  end



  # --- Security Tests ---

  test "should not expose sensitive information in error pages" do
    sign_in @user

    # Try to trigger an error
    get task_path(999999)

    assert_redirected_to pages_home_path
    # Should not expose internal information
    assert_not_includes flash[:alert], "ActiveRecord"
    assert_not_includes flash[:alert], "SQL"
  end

  test "authentication should be enforced on all actions" do
    # Test root path is public
    get root_path
    assert_response :success, "root_path should be public"
    # Test various controller actions without authentication
    protected_paths = [
      tasks_path,
      participants_path,
      actions_path,
      statistics_path,
      settings_path
    ]

    protected_paths.each do |path|
      get path
      assert_redirected_to new_user_session_path, "#{path} should require authentication"
    end
  end

  private

  def assert_assigns(variable_name)
    assert_not_nil assigns(variable_name), "@#{variable_name} should be assigned"
  end
end
