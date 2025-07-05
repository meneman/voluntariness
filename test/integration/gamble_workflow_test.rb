require "test_helper"

class GambleWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @participant = participants(:alice)
    sign_in @user
  end

  test "complete gambling workflow - participant selection to result" do
    # Step 1: Visit gambling page
    get gamble_path
    assert_response :success
    assert_select "h2", text: "Select Your Participant"
    assert_select "h3", count: 3

    # Step 2: Select participant
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Place Your Bet"

    # Step 3: Place bet and spin
    initial_bets = Bet.count

    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Spin the Wheel"

    # Verify backend data is passed to frontend
    assert_includes response.body, "data-spinning-wheel-target-angle-value"
    assert_includes response.body, "data-spinning-wheel-winning-item-value"

    # Verify bet creation (no point deduction or action creation)
    assert_equal initial_bets + 1, Bet.count

    # Verify winning item stored in session
    assert_not_nil session[:winning_item]
    winning_item = session[:winning_item]

    # Verify target angle calculation
    target_angle_match = response.body.match(/data-spinning-wheel-target-angle-value="([^"]+)"/)
    assert target_angle_match, "Target angle should be present in response"
    target_angle = target_angle_match[1].to_f

    # Calculate expected angle for winning item
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    winning_index = items.index(winning_item)
    degrees_per_section = 360.0 / items.length
    expected_angle = winning_index * degrees_per_section + (degrees_per_section / 2)

    assert_equal expected_angle, target_angle, "Target angle should match calculated angle for winning item"

    # Step 4: Get results
    initial_items = @participant.useable_items.count

    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Congratulations"
    assert_includes response.body, "Congratulations"

    # Verify useable item was created
    @participant.reload
    assert_equal initial_items + 1, @participant.useable_items.count

    created_item = @participant.useable_items.last
    assert_equal winning_item[:name], created_item.name

    # Verify session was cleared
    assert_nil session[:winning_item]

    # Step 5: Reset to start over
    post gamble_reset_path,
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Select Your Participant"
  end

  test "gambling workflow creates bet regardless of points" do
    # Remove all points from participant
    @participant.actions.destroy_all
    @participant.bets.destroy_all  # Also remove existing bets
    @participant.reload
    assert_equal 0, @participant.total_points.to_f

    # Step 1: Visit gambling page
    get gamble_path
    assert_response :success

    # Step 2: Select participant
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Place Your Bet"

    # Step 3: Spin with zero points (should still work)
    initial_bets = Bet.count

    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Spin the Wheel"

    # Verify bet was created even with no points
    assert_equal initial_bets + 1, Bet.count

    bet = Bet.last
    assert_equal @participant, bet.participant
    assert_equal 1.0, bet.cost
    assert_equal "pending", bet.outcome

    # Verify bet cost was deducted and no actions created
    @participant.reload
    assert_equal -1.0, @participant.total_points.to_f  # Bet cost of $1 deducted
    assert_equal 0, @participant.actions.count
  end

  test "multiple participants gambling workflow" do
    bob = participants(:bob)
    charlie = participants(:charlie)

    participants_data = [ @participant, bob, charlie ]

    participants_data.each_with_index do |participant, index|
      participant.reload
      initial_bets = Bet.count
      initial_items = participant.useable_items.count

      # Select participant
      post gamble_select_participant_path,
           params: { participant_id: participant.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success

      # Spin
      post gamble_spin_path,
           params: { participant_id: participant.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success

      # Verify backend-controlled data is present
      assert_includes response.body, "data-spinning-wheel-target-angle-value"
      assert_includes response.body, "data-spinning-wheel-winning-item-value"

      # Verify bet was created
      assert_equal initial_bets + 1, Bet.count

      # Get results
      post gamble_result_path,
           params: { participant_id: participant.id },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success

      # Verify each participant got their own item and bet was updated
      participant.reload
      assert_equal initial_items + 1, participant.useable_items.count

      # Verify bet outcome updated to won
      bet = Bet.last
      assert_equal "won", bet.outcome

      # Reset for next participant
      post gamble_reset_path,
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      assert_response :success
    end
  end

  test "gambling preserves user data isolation" do
    other_user = users(:two)
    other_participant = participants(:user_two_participant)

    # Verify we can't access other user's participants
    post gamble_select_participant_path,
         params: { participant_id: other_participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :not_found

    # Switch users
    sign_out @user
    sign_in other_user

    # Other user should be able to gamble with their own participant
    post gamble_select_participant_path,
         params: { participant_id: other_participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # But not with first user's participant
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :not_found
  end

  test "gambling workflow persists across requests" do
    # Step 1: Select participant
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # Step 2: Spin (stores winning item in session)
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    winning_item = session[:winning_item]
    assert_not_nil winning_item

    # Step 3: Simulate delay (like real spinning) then get results
    # The winning item should still be in session
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, winning_item[:name]

    # Session should be cleared after results
    assert_nil session[:winning_item]
  end

  test "error recovery in gambling workflow" do
    # Step 1: Start normally
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # Step 2: Spin successfully
    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success

    # Step 3: Simulate session loss (clear winning item)
    session.delete(:winning_item)

    # Step 4: Get results anyway - should fallback gracefully
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_includes response.body, "Congratulations"

    # Should still create a useable item (fallback mechanism)
    @participant.reload
    assert @participant.useable_items.count > 0
  end

  test "gambling with archived participants is excluded" do
    archived_participant = participants(:archived_participant)

    # Archived participant should not appear in selection
    get gamble_path
    assert_response :success
    assert_select ".participant-name", text: "Archived Person", count: 0

    # Should not be able to select archived participant directly
    post gamble_select_participant_path,
         params: { participant_id: archived_participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :not_found
  end

  test "gambling creates proper bet audit trail" do
    initial_bets = Bet.count

    # Complete gambling workflow
    post gamble_select_participant_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    post gamble_spin_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    # Verify bet was created (no actions or tasks)
    assert_equal initial_bets + 1, Bet.count

    bet = Bet.last
    assert_equal @participant, bet.participant
    assert_equal 1.0, bet.cost
    assert_equal "pending", bet.outcome
    assert_includes bet.description, "Gambling spin for"

    # Complete the workflow
    post gamble_result_path,
         params: { participant_id: @participant.id },
         headers: { "Accept" => "text/vnd.turbo-stream.html" }

    # Verify useable item creation
    useable_item = @participant.useable_items.last
    assert_not_nil useable_item
    assert_equal @participant, useable_item.participant
    assert_includes VoluntarinessConstants::OBTAINABLE_ITEMS.map { |item| item[:name] }, useable_item.name

    # Verify bet outcome was updated to won
    bet.reload
    assert_equal "won", bet.outcome
  end
end
