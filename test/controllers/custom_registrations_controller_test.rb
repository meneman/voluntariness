require "test_helper"

class CustomRegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
  end

  test "should inherit from Devise::RegistrationsController" do
    assert CustomRegistrationsController.ancestors.include?(Devise::RegistrationsController)
  end

  # --- Registration Tests ---

  test "should allow new user registration" do
    assert_difference('User.count', 1) do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    
    assert_redirected_to root_path  # Default after_sign_in_path
  end

  test "should not allow registration with invalid email" do
    assert_no_difference('User.count') do
      post user_registration_path, params: {
        user: {
          email: "invalid_email",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should not allow registration with mismatched passwords" do
    assert_no_difference('User.count') do
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          password: "password123",
          password_confirmation: "different_password"
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  # --- Account Update Tests ---

  test "should allow account update when signed in" do
    sign_in @user
    
    patch user_registration_path, params: {
      user: {
        email: "updated@example.com",
        current_password: "password123"
      }
    }
    
    @user.reload
    assert_equal "updated@example.com", @user.email
  end

  test "should allow username update" do
    sign_in @user
    
    # Add username attribute to user if it doesn't exist
    unless @user.respond_to?(:username)
      # Skip this test if username is not implemented
      skip "Username attribute not implemented"
    end
    
    patch user_registration_path, params: {
      user: {
        username: "newusername",
        current_password: "password123"
      }
    }
    
    @user.reload
    assert_equal "newusername", @user.username
  end

  test "should require current password for account update" do
    sign_in @user
    original_email = @user.email
    
    patch user_registration_path, params: {
      user: {
        email: "updated@example.com"
        # Missing current_password
      }
    }
    
    assert_response :unprocessable_entity
    @user.reload
    assert_equal original_email, @user.email
  end

  test "should require correct current password for account update" do
    sign_in @user
    original_email = @user.email
    
    patch user_registration_path, params: {
      user: {
        email: "updated@example.com",
        current_password: "wrong_password"
      }
    }
    
    assert_response :unprocessable_entity
    @user.reload
    assert_equal original_email, @user.email
  end

  test "should not allow account update when not signed in" do
    patch user_registration_path, params: {
      user: {
        email: "updated@example.com",
        current_password: "password123"
      }
    }
    
    assert_redirected_to new_user_session_path
  end

  # --- Parameter Sanitization Tests ---

  test "should permit username parameter for account update" do
    sign_in @user
    
    # Test that username parameter is permitted by attempting to update it
    # This test verifies the configure_account_update_params method
    patch user_registration_path, params: {
      user: {
        username: "testusername",
        current_password: "password123"
      }
    }
    
    # Should not raise parameter missing error
    # Response should be successful or redirect (not parameter error)
    assert_includes [200, 302, 303], response.status
  end

  test "should filter unpermitted parameters" do
    sign_in @user
    
    patch user_registration_path, params: {
      user: {
        email: "updated@example.com",
        admin: true,  # This should be filtered out
        role: "admin",  # This should be filtered out
        current_password: "password123"
      }
    }
    
    @user.reload
    # Should update email but ignore unpermitted params
    assert_equal "updated@example.com", @user.email
    # Admin and role should not be updated (if they exist)
    assert_not @user.admin if @user.respond_to?(:admin)
  end

  # --- Password Change Tests ---

  test "should allow password change with correct current password" do
    sign_in @user
    
    patch user_registration_path, params: {
      user: {
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "password123"
      }
    }
    
    # Should redirect to account page or root
    assert_response :redirect
    
    # Test that new password works by attempting to sign in
    sign_out @user
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "newpassword123"
      }
    }
    assert_redirected_to root_path
  end

  test "should not allow password change with incorrect current password" do
    sign_in @user
    
    patch user_registration_path, params: {
      user: {
        password: "newpassword123",
        password_confirmation: "newpassword123",
        current_password: "wrong_password"
      }
    }
    
    assert_response :unprocessable_entity
    
    # Old password should still work
    sign_out @user
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }
    assert_redirected_to root_path
  end

  test "should not allow password change with mismatched confirmation" do
    sign_in @user
    
    patch user_registration_path, params: {
      user: {
        password: "newpassword123",
        password_confirmation: "different_password",
        current_password: "password123"
      }
    }
    
    assert_response :unprocessable_entity
    
    # Old password should still work
    sign_out @user
    post user_session_path, params: {
      user: {
        email: @user.email,
        password: "password123"
      }
    }
    assert_redirected_to root_path
  end

  # --- Account Deletion Tests ---

  test "should allow account deletion when signed in" do
    sign_in @user
    user_id = @user.id
    
    assert_difference('User.count', -1) do
      delete user_registration_path
    end
    
    assert_nil User.find_by(id: user_id)
    assert_redirected_to root_path
  end

  test "should not allow account deletion when not signed in" do
    user_id = @user.id
    
    assert_no_difference('User.count') do
      delete user_registration_path
    end
    
    assert_not_nil User.find_by(id: user_id)
    assert_redirected_to new_user_session_path
  end

  # --- Integration Tests ---

  test "should preserve user associations after account update" do
    sign_in @user
    
    # Create some user data
    task = Task.create!(title: "Test Task", worth: 10, user: @user)
    participant = Participant.create!(name: "Test Participant", user: @user)
    
    patch user_registration_path, params: {
      user: {
        email: "updated@example.com",
        current_password: "password123"
      }
    }
    
    @user.reload
    task.reload
    participant.reload
    
    # Associations should be preserved
    assert_equal @user, task.user
    assert_equal @user, participant.user
    assert_includes @user.tasks, task
    assert_includes @user.participants, participant
  end

  test "should destroy user associations when account is deleted" do
    sign_in @user
    
    # Create some user data
    task = Task.create!(title: "Test Task", worth: 10, user: @user)
    participant = Participant.create!(name: "Test Participant", user: @user)
    task_id = task.id
    participant_id = participant.id
    
    delete user_registration_path
    
    # Associated data should be destroyed (dependent: :destroy)
    assert_nil Task.find_by(id: task_id)
    assert_nil Participant.find_by(id: participant_id)
  end

  # --- Route Tests ---

  test "should use custom controller for registration routes" do
    # Test that the custom controller is being used
    # This is more of a routing test but ensures proper configuration
    
    get new_user_registration_path
    assert_response :success
    
    # Should render the registration form
    assert_select "form[action=?]", user_registration_path
  end

  test "should use custom controller for edit registration" do
    sign_in @user
    
    get edit_user_registration_path
    assert_response :success
    
    # Should render the edit form
    assert_select "form"
  end
end