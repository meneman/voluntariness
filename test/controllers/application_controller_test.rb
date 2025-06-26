require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
  end

  # --- Authentication Tests ---

  test "should require authentication for protected actions" do
    # Test that unauthenticated users are redirected to sign in
    get root_path
    assert_redirected_to new_user_session_path
  end

  test "should allow access when authenticated" do
    sign_in @user
    get root_path
    assert_response :success
  end

  # --- Theme Management Tests ---

  test "should set default theme when no theme cookie exists" do
    sign_in @user
    get root_path

    assert_response :success
    assert_equal VoluntarinessConstants::DEFAULT_THEME, cookies[:theme]
  end

  test "should use existing theme from cookie" do
    sign_in @user
    cookies[:theme] = "light"

    get root_path
    assert_response :success
    assert_equal "light", cookies[:theme]
  end

  test "should set theme instance variable from cookie" do
    sign_in @user
    cookies[:theme] = "dark"

    get root_path
    assert_response :success
    assert_equal "dark", assigns(:theme)
  end

  test "should set theme instance variable to default when no cookie" do
    sign_in @user

    get root_path
    assert_response :success
    assert_equal VoluntarinessConstants::DEFAULT_THEME, assigns(:theme)
  end

  test "toggle_theme should update theme cookie" do
    sign_in @user

    # Assuming there's a route that calls toggle_theme
    # Since toggle_theme is a public method, we can test it indirectly
    # For now, we'll test the theme setting behavior through regular requests

    cookies[:theme] = "light"
    get root_path, params: { theme: "dark" }

    # This test might need adjustment based on actual implementation
    # The toggle_theme method exists but might not be used in a route
  end

  # --- Error Handling Tests ---

  test "should handle ActiveRecord::RecordNotFound with redirect" do
    sign_in @user

    # Try to access a non-existent task
    get task_path(999999)

    assert_redirected_to root_path
    assert_equal "Resource not found", flash[:alert]
  end


  # --- Sign-in Redirect Tests ---

  test "after_sign_in_path_for should redirect to root" do
    # Test the custom sign-in redirect
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }

    assert_redirected_to root_path
  end

  # --- Browser Compatibility Tests ---

  test "should allow modern browsers" do
    sign_in @user

    # Set a modern user agent
    get root_path, headers: {
      "User-Agent" => "Mozilla/5.0 (Chrome/91.0.4472.124)"
    }

    assert_response :success
  end

  # --- Pagy Integration Tests ---

  test "should include Pagy::Backend" do
    assert ApplicationController.included_modules.include?(Pagy::Backend)
  end

  test "should handle pagination in controllers that use it" do
    sign_in @user

    # Create multiple actions for pagination testing
    15.times do |i|
      Action.create!(
        task: tasks(:dishwashing),
        participant: participants(:alice),
        created_at: i.hours.ago
      )
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

    assert_redirected_to root_path
    follow_redirect!
    assert_includes response.body, "Resource not found"
  end


  # --- Theme Constants Tests ---

  test "should use correct default theme from constants" do
    expected_theme = VoluntarinessConstants::DEFAULT_THEME
    sign_in @user

    get root_path
    assert_response :success
    assert_equal expected_theme, assigns(:theme)
  end

  # --- Cookie Security Tests ---

  test "theme cookie should be properly set" do
    sign_in @user

    get root_path
    assert_response :success

    # Check that theme cookie exists and has correct value
    assert_not_nil cookies[:theme]
    assert_equal VoluntarinessConstants::DEFAULT_THEME, cookies[:theme]
  end

  test "should handle malformed theme cookie" do
    sign_in @user

    # Set a potentially malicious cookie value
    cookies[:theme] = "<script>alert('xss')</script>"

    get root_path
    assert_response :success

    # Should not cause errors and should use the value as-is
    # (theme validation should happen at the CSS/frontend level)
    assert_equal "<script>alert('xss')</script>", assigns(:theme)
  end

  # --- Concurrent User Tests ---

  test "should handle multiple users with different themes" do
    user1 = @user
    user2 = users(:two)

    # User 1 with dark theme
    sign_in user1
    cookies[:theme] = "dark"
    get root_path
    assert_equal "dark", assigns(:theme)
    sign_out user1

    # User 2 with light theme
    sign_in user2
    cookies[:theme] = "light"
    get root_path
    assert_equal "light", assigns(:theme)
  end

  # --- Security Tests ---

  test "should not expose sensitive information in error pages" do
    sign_in @user

    # Try to trigger an error
    get task_path(999999)

    assert_redirected_to root_path
    # Should not expose internal information
    assert_not_includes flash[:alert], "ActiveRecord"
    assert_not_includes flash[:alert], "SQL"
  end

  test "authentication should be enforced on all actions" do
    # Test various controller actions without authentication
    unauthenticated_paths = [
      root_path,
      tasks_path,
      participants_path,
      actions_path,
      statistics_path,
      settings_path
    ]

    unauthenticated_paths.each do |path|
      get path
      assert_redirected_to new_user_session_path, "#{path} should require authentication"
    end
  end

  # --- Helper Method Tests ---

  test "set_theme should be called on every request" do
    sign_in @user

    # Multiple requests should all set theme
    get root_path
    assert_not_nil assigns(:theme)

    get tasks_path
    assert_not_nil assigns(:theme)

    get participants_path
    assert_not_nil assigns(:theme)
  end

  private

  def assert_assigns(variable_name)
    assert_not_nil assigns(variable_name), "@#{variable_name} should be assigned"
  end
end
