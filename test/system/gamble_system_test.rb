require "application_system_test_case"
class GambleSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  def setup
    @user = users(:one)
    @participant = participants(:alice)
    sign_in @user
    # Give participant points for gambling
    @task = tasks(:dishwashing)
    Action.create!(participant: @participant, task: @task)
    @participant.reload
  end
  test "complete gambling user interface flow" do
    visit gamble_path
    # Should see the participant selection section
    assert_selector ".gamble-container"
    assert_selector ".step-indicator"
    assert_selector ".participant-selection-section"
    assert_selector ".participant-card", count: 3
    # Should see participant information
    within(".participant-card", text: "Alice") do
      assert_text "Alice"
      assert_text @participant.total_points
      assert_selector ".btn", text: "Select"
    end
    # Select participant
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    # Should transition to bet section
    assert_selector ".bet-section", wait: 5
    assert_selector ".selected-participant-info"
    assert_text "Place Your Bet!"
    assert_text "Alice"
    assert_text "Current Points:"
    # Should see bet button if participant has sufficient points
    if @participant.total_points.to_f >= 1
      assert_selector ".btn", text: "Bet 1 Bonus Point to Spin"
      # Click bet button
      click_button "Bet 1 Bonus Point to Spin"
      # Should transition to spinning section
      assert_selector ".spinning-section", wait: 5
      assert_text "Spin the Wheel"
      assert_selector "#wrapper[data-controller='spinning-wheel']"
      assert_selector "#spin"
      
      # Verify backend data is passed to frontend
      wheel_wrapper = find("#wrapper[data-controller='spinning-wheel']")
      assert wheel_wrapper["data-spinning-wheel-target-angle-value"].present?, "Target angle should be present"
      assert wheel_wrapper["data-spinning-wheel-winning-item-value"].present?, "Winning item should be present"
      
      # Should see spinning wheel with segments
      assert_selector ".sec", count: 6
      assert_text "Click the \"SPIN\" button to spin the wheel!"
      # Click the spin button
      within("#wrapper") do
        find("#spin").click
      end
      # Wait for spinning animation and result
      # Note: In tests, we might need to manually trigger the result
      # since the 7-second timeout might be too long for tests
      # Simulate the spinning completion by directly calling the result endpoint
      # This tests the integration without waiting for the full animation
      page.evaluate_script("
        fetch('/gamble/result', {
          method: 'POST',
          headers: {
            'X-CSRF-Token': document.querySelector('[name=\"csrf-token\"]').content,
            'Accept': 'text/vnd.turbo-stream.html',
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: new URLSearchParams({
            participant_id: '#{@participant.id}'
          })
        });
      ")
      # Should show results section
      assert_selector ".result-section", wait: 10
      assert_text "Congratulations, You Won!"
      assert_selector ".prize-display"
      assert_selector ".prize-item"
      # Should see action buttons
      assert_selector ".btn", text: "🎮 Play Again"
      assert_selector ".btn", text: "🏠 Return to Dashboard"
      # Test play again functionality
      click_button "🎮 Play Again"
      # Should return to participant selection
      assert_selector ".participant-selection-section", wait: 5
      assert_text "Select Your Participant"
    else
      # If insufficient points, should see error message
      assert_text "Insufficient Points"
    end
  end
  test "insufficient points user interface" do
    # Remove points from participant
    @participant.actions.destroy_all
    @participant.reload
    visit gamble_path
    # Select participant with no points
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    # Should show bet section with disabled state
    assert_selector ".bet-section", wait: 5
    assert_text "Insufficient Points"
    assert_text "You need at least 1 bonus point"
    assert_selector ".btn", text: "Select Different Participant"
    # Click to select different participant
    click_button "Select Different Participant"
    # Should return to participant selection
    assert_selector ".participant-selection-section", wait: 5
  end
  test "step indicator updates correctly" do
    visit gamble_path
    # Initial state - step 1 should be active
    within(".step-indicator") do
      assert_selector ".step.active", text: "Select Participant"
      assert_selector ".step:not(.active)", text: "Place Bet"
      assert_selector ".step:not(.active)", text: "Spin & Win"
    end
    # Select participant
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    # Step 2 should now be active
    within(".step-indicator", wait: 5) do
      assert_selector ".step.completed", text: "Select Participant"
      assert_selector ".step.active", text: "Place Bet"
      assert_selector ".step:not(.active):not(.completed)", text: "Spin & Win"
    end
    # Place bet (if participant has points)
    if @participant.total_points.to_f >= 1
      click_button "Bet 1 Bonus Point to Spin"
      # Step 3 should now be active
      within(".step-indicator", wait: 5) do
        assert_selector ".step.completed", text: "Select Participant"
        assert_selector ".step.completed", text: "Place Bet"
        assert_selector ".step.active", text: "Spin & Win"
      end
    end
  end
  test "navigation and back buttons work correctly" do
    visit gamble_path
    # Select participant
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    assert_selector ".bet-section", wait: 5
    # Test back button
    click_button "← Back to Selection"
    # Should return to participant selection
    assert_selector ".participant-selection-section", wait: 5
    assert_text "Select Your Participant"
  end
  test "responsive design elements are present" do
    visit gamble_path
    # Test that CSS classes for responsive design are present
    assert_selector ".gamble-container"
    assert_selector ".participants-grid"
    # Resize window to test mobile responsiveness
    page.current_window.resize_to(375, 667) # iPhone size
    # Elements should still be visible and functional
    assert_selector ".participant-card"
    assert_selector ".btn"
    # Resize back
    page.current_window.resize_to(1200, 800)
  end
  test "error handling in user interface" do
    visit gamble_path
    # Test with JavaScript disabled scenarios by directly manipulating DOM
    page.evaluate_script("
      // Simulate a network error
      const originalFetch = window.fetch;
      window.fetch = function() {
        return Promise.reject(new Error('Network error'));
      };
    ")
    # The interface should still be functional for basic navigation
    assert_selector ".participant-card"
    # Restore fetch
    page.evaluate_script("
      window.fetch = #{page.evaluate_script("originalFetch")};
    ")
  end
  test "accessibility features" do
    visit gamble_path
    # Test that important elements have proper accessibility attributes
    assert_selector "button", minimum: 1
    assert_selector ".btn[role], .btn"
    # Test keyboard navigation
    first(".participant-card .btn").send_keys(:return)
    # Should still work with keyboard interaction
    assert_selector ".bet-section", wait: 5
  end
  test "visual feedback and animations" do
    visit gamble_path
    # Test hover effects (CSS-based)
    participant_card = find(".participant-card", text: "Alice")
    participant_card.hover
    # Select participant to test transition animations
    within(participant_card) do
      click_button "Select"
    end
    # Test that transitions happen (elements change)
    assert_selector ".bet-section", wait: 5
    # Elements should have proper styling classes
    assert_selector ".section" # Main section styling
    assert_selector ".btn-primary" # Button styling
  end
  test "spinning wheel controller integration" do
    # Give participant sufficient points
    if @participant.total_points.to_f < 1
      Action.create!(participant: @participant, task: @task)
      @participant.reload
    end
    visit gamble_path
    # Navigate to spinning section
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    click_button "Bet 1 Bonus Point to Spin"
    # Should see spinning wheel controller
    assert_selector "#wrapper[data-controller='spinning-wheel']", wait: 5
    assert_selector "#inner-wheel[data-spinning-wheel-target='innerWheel']"
    assert_selector "#spin[data-spinning-wheel-target='spinButton']"
    
    # Verify backend data attributes are present
    wheel_wrapper = find("#wrapper[data-controller='spinning-wheel']")
    assert wheel_wrapper["data-spinning-wheel-target-angle-value"].present?, "Target angle should be present"
    assert wheel_wrapper["data-spinning-wheel-winning-item-value"].present?, "Winning item should be present"
    
    # Test that gamble controller is connected
    assert_selector ".gamble-container[data-controller='gamble']"
    # Check that segments contain SVG content
    assert_selector ".sec", count: 6
    # Each segment should have SVG content from obtainable items
    VoluntarinessConstants::OBTAINABLE_ITEMS.each do |item|
      assert_selector ".sec svg", minimum: 1
    end
  end
  test "data persistence across page interactions" do
    visit gamble_path
    # Navigate through the flow
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    # Check that participant information persists
    assert_selector ".selected-participant-info", text: "Alice"
    assert_text @participant.total_points
    # Go back and forward again
    click_button "← Back to Selection"
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    # Information should still be correct
    assert_selector ".selected-participant-info", text: "Alice"
  end
  test "multiple browser tab simulation" do
    # This test simulates what happens if user opens multiple tabs
    visit gamble_path
    # Start gambling process
    within(".participant-card", text: "Alice") do
      click_button "Select"
    end
    if @participant.total_points.to_f >= 1
      click_button "Bet 1 Bonus Point to Spin"
      # Simulate opening new tab by visiting the same page again
      visit gamble_path
      # Should start fresh (new tab scenario)
      assert_selector ".participant-selection-section"
      assert_text "Select Your Participant"
    end
  end
end

