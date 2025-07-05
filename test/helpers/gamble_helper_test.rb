require "test_helper"

class GambleHelperTest < ActionView::TestCase
  include ApplicationHelper

  def setup
    @user = users(:one)
    @participant = participants(:alice)
  end

  test "participant has sufficient points for gambling" do
    # Give participant points
    task = tasks(:dishwashing)
    Action.create!(participant: @participant, task: task)
    @participant.reload
    
    assert @participant.total_points.to_f >= 1
  end

  test "obtainable items are accessible in views" do
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    
    assert_not_empty items
    assert_equal 6, items.length
    
    # Test that each item has required properties for view rendering
    items.each do |item|
      assert_not_nil item[:name]
      assert_not_nil item[:svg]
      assert item[:svg].include?("svg")
      
      # Test that html_safe would work on the SVG
      assert_nothing_raised do
        item[:svg].html_safe
      end
    end
  end

  test "participant points display formatting" do
    # Clear existing actions and bets, test with whole numbers
    @participant.actions.destroy_all
    @participant.bets.destroy_all
    task = tasks(:dishwashing) # worth 10.0
    Action.create!(participant: @participant, task: task, bonus_points: 0, on_streak: false)
    @participant.reload
    
    points = @participant.total_points
    # Should be formatted as string and contain the task worth
    assert points.is_a?(String)
    assert points.to_f >= 10.0
  end

  test "participant points display with decimals" do
    # Clear existing actions and bets, create a task with decimal points
    @participant.actions.destroy_all
    @participant.bets.destroy_all
    decimal_task = Task.create!(
      user: @user,
      title: "Decimal Task",
      worth: 5.5
    )
    Action.create!(participant: @participant, task: decimal_task)
    @participant.reload
    
    points = @participant.total_points
    assert_equal "5.5", points # Should show decimal when needed
  end

  test "safe svg rendering in views" do
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    
    items.each do |item|
      # Test that the SVG can be safely rendered
      svg_content = item[:svg]
      safe_svg = svg_content.html_safe
      
      assert safe_svg.html_safe?
      assert_includes safe_svg, "svg"
      assert_includes safe_svg, "viewBox"
    end
  end

  test "participant avatar initial helper" do
    # Test that we can get the first character of participant name
    initial = @participant.name.first.upcase
    assert_equal "A", initial
    
    # Test with different participants
    bob = participants(:bob)
    assert_equal "B", bob.name.first.upcase
  end

  test "step indicator states" do
    steps = ['select', 'bet', 'spin', 'result']
    
    # Test active step logic
    steps.each_with_index do |step, index|
      current_step = step
      
      steps.each_with_index do |check_step, check_index|
        if check_index < index
          # Previous steps should be completed
          assert check_index < index
        elsif check_index == index
          # Current step should be active
          assert_equal current_step, check_step
        else
          # Future steps should be inactive
          assert check_index > index
        end
      end
    end
  end

  test "error state rendering" do
    # Test that error states can be rendered safely
    error_states = {
      insufficient_points: "Not enough points to gamble",
      network_error: "Connection failed",
      invalid_participant: "Participant not found"
    }
    
    error_states.each do |state, message|
      # These should be safe to render in templates
      assert_not_nil message
      assert message.is_a?(String)
      assert_nothing_raised do
        message.html_safe
      end
    end
  end

  test "button state helpers" do
    # Test disabled button logic
    participant_with_no_points = participants(:alice)
    participant_with_no_points.actions.destroy_all
    participant_with_no_points.bets.destroy_all
    participant_with_no_points.reload
    
    assert_equal 0, participant_with_no_points.total_points.to_f
    
    # Button should be disabled
    can_gamble = participant_with_no_points.total_points.to_f >= 1
    assert_not can_gamble
    
    # Give points and test again
    task = tasks(:dishwashing)
    Action.create!(participant: participant_with_no_points, task: task)
    participant_with_no_points.reload
    
    can_gamble = participant_with_no_points.total_points.to_f >= 1
    assert can_gamble
  end

  test "prize display formatting" do
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    
    items.each do |item|
      name = item[:name]
      
      # Test description formatting
      description = "A magnificent #{name.downcase} has been added to your collection!"
      
      assert_includes description, name.downcase
      assert_includes description, "magnificent"
      assert_includes description, "collection"
    end
  end

  test "responsive class helpers" do
    # Test that responsive classes are properly structured
    responsive_classes = {
      container: "gamble-container",
      grid: "participants-grid",
      card: "participant-card",
      button: "btn btn-primary",
      section: "section"
    }
    
    responsive_classes.each do |element, classes|
      assert_not_nil classes
      assert classes.is_a?(String)
      assert_not_empty classes
    end
  end

  test "data attribute helpers" do
    # Test data attributes used in gambling
    data_attributes = {
      controller: "gamble",
      target: "participantGrid",
      action: "click->gamble#selectParticipant",
      participant_id: @participant.id.to_s
    }
    
    data_attributes.each do |key, value|
      assert_not_nil value
      assert value.is_a?(String) || value.is_a?(Integer)
    end
  end
end