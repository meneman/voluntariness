require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    sign_in @user
  end

  test "should require authentication for all actions" do
    sign_out @user
    
    patch toggle_streak_boni_path, params: { enabled: "1" }
    assert_redirected_to new_user_session_path
    
    patch toggle_overdue_bonus_path, params: { enabled: "1" }
    assert_redirected_to new_user_session_path
    
    patch update_streak_bonus_days_threshold_path, params: { days_threshold: "3" }
    assert_redirected_to new_user_session_path
  end

  # --- Toggle Streak Boni Tests ---

  test "should enable streak boni" do
    @user.update!(streak_boni_enabled: false)
    
    patch toggle_streak_boni_path, params: { enabled: "1" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    @user.reload
    assert @user.streak_boni_enabled
    assert assigns(:enabled)
  end

  test "should disable streak boni" do
    @user.update!(streak_boni_enabled: true)
    
    patch toggle_streak_boni_path, params: { enabled: "0" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    @user.reload
    assert_not @user.streak_boni_enabled
    assert_not assigns(:enabled)
  end

  test "should handle missing enabled parameter for streak boni" do
    @user.update!(streak_boni_enabled: true)
    
    patch toggle_streak_boni_path, as: :turbo_stream
    assert_response :success
    
    @user.reload
    # Should be false when enabled param is nil
    assert_not @user.streak_boni_enabled
  end

  test "should handle non-boolean enabled parameter for streak boni" do
    @user.update!(streak_boni_enabled: false)
    
    patch toggle_streak_boni_path, params: { enabled: "invalid" }, as: :turbo_stream
    assert_response :success
    
    @user.reload
    # Should be false for any value other than "1"
    assert_not @user.streak_boni_enabled
  end

  # --- Toggle Overdue Bonus Tests ---

  test "should enable overdue bonus" do
    @user.update!(overdue_bonus_enabled: false)
    
    patch toggle_overdue_bonus_path, params: { enabled: "1" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    @user.reload
    assert @user.overdue_bonus_enabled
  end

  test "should disable overdue bonus" do
    @user.update!(overdue_bonus_enabled: true)
    
    patch toggle_overdue_bonus_path, params: { enabled: "0" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    @user.reload
    assert_not @user.overdue_bonus_enabled
  end

  test "should handle missing enabled parameter for overdue bonus" do
    @user.update!(overdue_bonus_enabled: true)
    
    patch toggle_overdue_bonus_path, as: :turbo_stream
    assert_response :success
    
    @user.reload
    # Should be false when enabled param is nil
    assert_not @user.overdue_bonus_enabled
  end

  test "should handle non-boolean enabled parameter for overdue bonus" do
    @user.update!(overdue_bonus_enabled: false)
    
    patch toggle_overdue_bonus_path, params: { enabled: "invalid" }, as: :turbo_stream
    assert_response :success
    
    @user.reload
    # Should be false for any value other than "1"
    assert_not @user.overdue_bonus_enabled
  end

  # --- Update Streak Bonus Days Threshold Tests ---

  test "should update streak bonus days threshold" do
    original_threshold = @user.streak_boni_days_threshold
    new_threshold = 7
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: new_threshold.to_s }, 
          as: :turbo_stream
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    @user.reload
    assert_equal new_threshold, @user.streak_boni_days_threshold
    assert_includes flash[:notice], "#{new_threshold} days"
  end

  test "should enforce minimum threshold" do
    min_threshold = VoluntarinessConstants::MIN_STREAK_THRESHOLD
    below_min = min_threshold - 1
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: below_min.to_s }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    assert_equal min_threshold, @user.streak_boni_days_threshold
    assert_includes flash[:notice], "#{min_threshold} days"
  end

  test "should handle zero threshold" do
    min_threshold = VoluntarinessConstants::MIN_STREAK_THRESHOLD
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: "0" }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    assert_equal min_threshold, @user.streak_boni_days_threshold
  end

  test "should handle negative threshold" do
    min_threshold = VoluntarinessConstants::MIN_STREAK_THRESHOLD
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: "-5" }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    assert_equal min_threshold, @user.streak_boni_days_threshold
  end

  test "should handle non-numeric threshold" do
    min_threshold = VoluntarinessConstants::MIN_STREAK_THRESHOLD
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: "invalid" }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    # to_i on "invalid" returns 0, which gets set to minimum
    assert_equal min_threshold, @user.streak_boni_days_threshold
  end

  test "should handle missing threshold parameter" do
    min_threshold = VoluntarinessConstants::MIN_STREAK_THRESHOLD
    original_threshold = @user.streak_boni_days_threshold
    
    patch update_streak_bonus_days_threshold_path, as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    # Should set to minimum when param is missing (nil.to_i = 0)
    assert_equal min_threshold, @user.streak_boni_days_threshold
  end

  test "should accept valid high threshold" do
    high_threshold = 30
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: high_threshold.to_s }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    assert_equal high_threshold, @user.streak_boni_days_threshold
    assert_includes flash[:notice], "#{high_threshold} days"
  end

  test "should handle decimal threshold by truncating" do
    decimal_value = "5.7"
    expected_value = 5
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: decimal_value }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    assert_equal expected_value, @user.streak_boni_days_threshold
  end

  test "should render turbo stream response for threshold update" do
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: "5" }, 
          as: :turbo_stream
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    
    # Check that the response includes the flash partial
    assert_includes response.body, "flash"
  end

  test "all actions should only respond to turbo stream" do
    # Test that these actions don't work with HTML format
    assert_raises(ActionController::UnknownFormat) do
      patch toggle_streak_boni_path, params: { enabled: "1" }
    end
    
    assert_raises(ActionController::UnknownFormat) do
      patch toggle_overdue_bonus_path, params: { enabled: "1" }
    end
    
    assert_raises(ActionController::UnknownFormat) do
      patch update_streak_bonus_days_threshold_path, params: { days_threshold: "5" }
    end
  end

  test "should preserve other user attributes when updating settings" do
    original_email = @user.email
    original_created_at = @user.created_at
    
    patch toggle_streak_boni_path, params: { enabled: "1" }, as: :turbo_stream
    assert_response :success
    
    @user.reload
    assert_equal original_email, @user.email
    assert_equal original_created_at, @user.created_at
  end

  test "should handle database errors gracefully" do
    # Mock update to fail
    @user.define_singleton_method(:update) { false }
    
    # Should not raise error
    assert_nothing_raised do
      patch toggle_streak_boni_path, params: { enabled: "1" }, as: :turbo_stream
    end
  end

  test "constants should be properly used" do
    min_threshold = VoluntarinessConstants::MIN_STREAK_THRESHOLD
    
    patch update_streak_bonus_days_threshold_path, 
          params: { days_threshold: "1" }, 
          as: :turbo_stream
    
    assert_response :success
    
    @user.reload
    assert_equal min_threshold, @user.streak_boni_days_threshold
  end
end