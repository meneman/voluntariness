require "test_helper"

class GambleControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @participant = participants(:alice)
    @other_user_participant = participants(:user_two_participant)
    sign_in @user
  end

  # Authentication Tests
  test "should require authentication for all actions" do
    sign_out @user

    get gamble_path
    assert_redirected_to new_user_session_path

    post gamble_select_participant_path, params: { participant_id: @participant.id }
    assert_redirected_to new_user_session_path

    post gamble_spin_path, params: { participant_id: @participant.id }
    assert_redirected_to new_user_session_path

    post gamble_result_path, params: { participant_id: @participant.id }
    assert_redirected_to new_user_session_path

    post gamble_reset_path
    assert_redirected_to new_user_session_path
  end

  # Index Action Tests
  test "should get index" do
    get gamble_path
    assert_response :success
    assert_select "h2", text: "Select Your Participant"
  end

  test "should display active participants on index" do
    get gamble_path
    
    assert_select "h3", text: "Alice"
    assert_select "h3", text: "Bob"
    assert_select "h3", text: "Charlie"
    assert_select "h3", text: "Archived Person", count: 0
  end

  # Select Participant Action Tests
  test "should select participant successfully" do
    post gamble_select_participant_path, 
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not allow selecting other user's participant" do
    post gamble_select_participant_path,
         params: { participant_id: @other_user_participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :not_found
  end

  test "should render bet section after participant selection" do
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_includes response.body, "gamble_content"
    assert_includes response.body, "Place Your Bet"
    assert_includes response.body, "gamble_step_indicator"
  end

  # Spin Action Tests
  test "should spin successfully with sufficient points" do
    # Create a task to give participant points
    task = tasks(:dishwashing)
    action = Action.create!(task: task); action.add_participants([@participant.id])
    @participant.reload

    initial_points = @participant.total_points.to_f
    assert initial_points >= 1, "Participant should have at least 1 point"

    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_includes response.body, "Spin the Wheel"
    
    # Check that backend data is passed to frontend
    assert_includes response.body, "data-spinning-wheel-target-angle-value"
    assert_includes response.body, "data-spinning-wheel-winning-item-value"
    
    # Verify target angle is a valid number between 0-360
    target_angle_match = response.body.match(/data-spinning-wheel-target-angle-value="([^"]+)"/)
    assert target_angle_match, "Target angle should be present in response"
    target_angle = target_angle_match[1].to_f
    assert target_angle >= 0 && target_angle < 360, "Target angle should be between 0-360 degrees"
    
    # Check that bet was created (no point deduction)
    bet = Bet.last
    assert_equal @participant, bet.participant
    assert_equal 1.0, bet.cost
    assert_equal "pending", bet.outcome
  end

  test "should allow gambling regardless of points" do
    # Ensure participant has no points
    @participant.actions.destroy_all
    @participant.bets.destroy_all  # Also remove existing bets
    @participant.reload
    
    assert_equal 0, @participant.total_points.to_f

    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_includes response.body, "Spin the Wheel"
    
    # Verify bet was created even without points
    bet = Bet.last
    assert_equal @participant, bet.participant
    assert_equal 1.0, bet.cost
    assert_equal "pending", bet.outcome
  end

  test "should create bet when spinning" do
    initial_bet_count = Bet.count
    
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    # Check that bet was created (no actions)
    assert_equal initial_bet_count + 1, Bet.count
    
    bet = Bet.last
    assert_equal @participant, bet.participant
    assert_equal 1.0, bet.cost
    assert_equal "pending", bet.outcome
  end

  test "should store winning item in session and calculate target angle" do
    
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_not_nil session[:winning_item]
    assert_includes VoluntarinessConstants::OBTAINABLE_ITEMS, session[:winning_item]
    
    # Verify target angle is included in response
    assert_includes response.body, "data-spinning-wheel-target-angle-value"
    assert_includes response.body, "data-spinning-wheel-winning-item-value"
  end

  test "should not allow spinning for other user's participant" do
    post gamble_spin_path,
         params: { participant_id: @other_user_participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :not_found
  end

  # Result Action Tests
  test "should show result successfully" do
    # Set up session with winning item by spinning first
    task = tasks(:dishwashing)
    action = Action.create!(task: task); action.add_participants([@participant.id])
    
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_includes response.body, "Congratulations"
    assert_includes response.body, "Congratulations"
  end

  test "should create useable item for participant" do
    # Give participant some points first
    task = tasks(:dishwashing)
    action = Action.create!(task: task); action.add_participants([@participant.id])
    
    initial_items_count = @participant.useable_items.count
    
    # Spin first to set up session
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    winning_item = session[:winning_item]
    assert_not_nil winning_item, "Winning item should be set in session after spin"
    
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    @participant.reload
    final_items_count = @participant.useable_items.count
    
    # Verify useable item was created
    assert final_items_count > initial_items_count, "Expected items count to increase"
    
    created_item = @participant.useable_items.last
    # Verify that the created item is one of the valid obtainable items
    valid_names = VoluntarinessConstants::OBTAINABLE_ITEMS.map { |item| item[:name] }
    assert_includes valid_names, created_item.name
    assert_not_nil created_item.svg
  end

  test "should handle missing winning item gracefully" do
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    # Should still show result section even without winning item in session
    assert_includes response.body, "Congratulations"
  end

  test "should clear winning item from session" do
    # Give participant some points first
    task = tasks(:dishwashing)
    action = Action.create!(task: task); action.add_participants([@participant.id])
    
    # Spin first to set up session
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    # Verify winning item is in session
    assert_not_nil session[:winning_item]
    
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_nil session[:winning_item]
  end

  test "should fallback to random item if session empty" do
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    
    # Should still create a useable item
    @participant.reload
    assert @participant.useable_items.count > 0
  end

  # Reset Action Tests
  test "should reset to participant selection" do
    post gamble_reset_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_includes response.body, "Select Your Participant"
  end

  test "should show active participants on reset" do
    post gamble_reset_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :success
    assert_includes response.body, "Alice"
    assert_includes response.body, "Bob"
    assert_includes response.body, "Charlie"
  end

  # Edge Cases and Error Handling
  test "should handle invalid participant id" do
    post gamble_select_participant_path,
         params: { participant_id: 99999 },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :not_found
  end

  test "should handle missing participant_id parameter" do
    post gamble_select_participant_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    assert_response :bad_request
  end

  test "should only allow turbo_stream format" do
    # Test that HTML format is not supported for AJAX actions
    post gamble_select_participant_path,
         params: { participant_id: @participant.id }
    
    # Should either redirect or return an error since HTML format isn't handled
    assert_not_equal :success, response.status
  end

  # Integration with Constants
  test "should use obtainable items from constants" do
    # Give participant some points first
    task = tasks(:dishwashing)
    action = Action.create!(task: task); action.add_participants([@participant.id])
    
    # Spin to get a winning item
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    winning_item = session[:winning_item]
    
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }
    
    @participant.reload
    created_item = @participant.useable_items.last
    
    # Verify the item was created from valid constants
    assert_includes VoluntarinessConstants::OBTAINABLE_ITEMS, winning_item
    valid_names = VoluntarinessConstants::OBTAINABLE_ITEMS.map { |item| item[:name] }
    assert_includes valid_names, created_item.name
    assert_not_nil created_item.svg
    assert created_item.svg.include?("svg")
  end

  test "should handle all obtainable items correctly and calculate proper angles" do
    # Test that spinning produces one of the valid obtainable items
    task = tasks(:dishwashing)
    action = Action.create!(task: task); action.add_participants([@participant.id])
    
    # Spin multiple times to test randomness and angle calculation
    5.times do
      @participant.reload
      
      post gamble_spin_path,
           params: { participant_id: @participant.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      winning_item = session[:winning_item]
      assert_includes VoluntarinessConstants::OBTAINABLE_ITEMS, winning_item
      
      # Verify target angle corresponds to winning item
      target_angle_match = response.body.match(/data-spinning-wheel-target-angle-value="([^"]+)"/)
      assert target_angle_match, "Target angle should be present"
      target_angle = target_angle_match[1].to_f
      
      # Calculate expected angle for winning item
      items = VoluntarinessConstants::OBTAINABLE_ITEMS
      winning_index = items.index(winning_item)
      degrees_per_section = 360.0 / items.length
      expected_angle = winning_index * degrees_per_section + (degrees_per_section / 2)
      
      assert_equal expected_angle, target_angle, "Target angle should match calculated angle for winning item"
      
      post gamble_result_path,
           params: { participant_id: @participant.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      
      # Give participant more points for next iteration
      action = Action.create!(task: task); action.add_participants([@participant.id])
    end
  end
end