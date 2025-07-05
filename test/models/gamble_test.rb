require "test_helper"

class GambleTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @participant = participants(:alice)
    @task = tasks(:dishwashing)
  end

  test "participant can have sufficient points for gambling" do
    # Give participant points
    Action.create!(participant: @participant, task: @task)
    @participant.reload
    
    assert @participant.total_points.to_f >= 1, "Participant should have at least 1 point for gambling"
  end

  test "participant points are correctly deducted during gambling" do
    # Give participant points
    Action.create!(participant: @participant, task: @task)
    @participant.reload
    initial_points = @participant.total_points.to_f
    
    # Create gambling task (negative points)
    gambling_task = Task.create!(
      user: @user,
      title: "Gamble Bet",
      worth: -1,
      description: "Point deducted for gambling"
    )
    
    # Create gambling action
    Action.create!(participant: @participant, task: gambling_task)
    @participant.reload
    
    assert_equal initial_points - 1, @participant.total_points.to_f
  end

  test "useable items can be created from obtainable items" do
    initial_count = @participant.useable_items.count
    
    # Test each obtainable item
    VoluntarinessConstants::OBTAINABLE_ITEMS.each do |item|
      created_item = UseableItem.create_from_obtainable(@participant, item[:name])
      
      assert_not_nil created_item
      assert_equal item[:name], created_item.name
      assert_equal item[:svg], created_item.svg
      assert_equal @participant, created_item.participant
    end
    
    @participant.reload
    assert_equal initial_count + VoluntarinessConstants::OBTAINABLE_ITEMS.length, @participant.useable_items.count
  end

  test "obtainable items constants are properly structured" do
    assert_not_empty VoluntarinessConstants::OBTAINABLE_ITEMS
    assert_equal 6, VoluntarinessConstants::OBTAINABLE_ITEMS.length
    
    VoluntarinessConstants::OBTAINABLE_ITEMS.each do |item|
      assert_not_nil item[:name], "Item should have a name"
      assert_not_nil item[:svg], "Item should have SVG content"
      assert item[:name].is_a?(String), "Item name should be a string"
      assert item[:svg].is_a?(String), "Item SVG should be a string"
      assert item[:svg].include?("svg"), "SVG should contain svg tag"
    end
  end

  test "participant with insufficient points cannot gamble" do
    # Ensure participant has no points
    @participant.actions.destroy_all
    @participant.bets.destroy_all  # Also remove existing bets
    @participant.reload
    
    assert_equal 0, @participant.total_points.to_f
    assert @participant.total_points.to_f < 1, "Participant should not have enough points to gamble"
  end

  test "gambling task creation is isolated per user" do
    user_two = users(:two)
    
    # Create gambling task for first user
    gambling_task_one = Task.create!(
      user: @user,
      title: "Gamble Bet",
      worth: -1,
      description: "Point deducted for gambling"
    )
    
    # Create gambling task for second user
    gambling_task_two = Task.create!(
      user: user_two,
      title: "Gamble Bet",
      worth: -1,
      description: "Point deducted for gambling"
    )
    
    assert_equal @user, gambling_task_one.user
    assert_equal user_two, gambling_task_two.user
    assert_not_equal gambling_task_one, gambling_task_two
  end

  test "useable items are properly associated with participants" do
    # Create useable item
    item_data = VoluntarinessConstants::OBTAINABLE_ITEMS.first
    useable_item = UseableItem.create_from_obtainable(@participant, item_data[:name])
    
    assert_equal @participant, useable_item.participant
    assert_equal @user, useable_item.participant.user
    
    # Verify it appears in participant's collection
    @participant.reload
    assert_includes @participant.useable_items, useable_item
  end

  test "multiple participants can have same items" do
    alice = participants(:alice)
    bob = participants(:bob)
    
    item_data = VoluntarinessConstants::OBTAINABLE_ITEMS.first
    
    alice_item = UseableItem.create_from_obtainable(alice, item_data[:name])
    bob_item = UseableItem.create_from_obtainable(bob, item_data[:name])
    
    assert_equal alice_item.name, bob_item.name
    assert_equal alice_item.svg, bob_item.svg
    assert_not_equal alice_item, bob_item
    assert_equal alice, alice_item.participant
    assert_equal bob, bob_item.participant
  end

  test "gambling action has correct attributes" do
    gambling_task = Task.create!(
      user: @user,
      title: "Gamble Bet",
      worth: -1,
      description: "Point deducted for gambling"
    )
    
    gambling_action = Action.create!(
      participant: @participant,
      task: gambling_task,
      bonus_points: 0
    )
    
    assert_equal @participant, gambling_action.participant
    assert_equal gambling_task, gambling_action.task
    assert_equal 0, gambling_action.bonus_points
    assert_equal(-1, gambling_action.task.worth)
    assert gambling_action.created_at.present?
  end

  test "participant total points calculation includes gambling actions" do
    # Give participant initial points
    positive_task = @task # worth 10.0
    Action.create!(participant: @participant, task: positive_task)
    @participant.reload
    
    initial_points = @participant.total_points.to_f
    
    # Gamble and lose points
    gambling_task = Task.create!(
      user: @user,
      title: "Gamble Bet",
      worth: -1
    )
    Action.create!(participant: @participant, task: gambling_task)
    @participant.reload
    
    expected_points = initial_points - 1
    assert_equal expected_points, @participant.total_points.to_f
  end

  test "obtainable items can be sampled randomly for backend winner selection" do
    # Test that random sampling works for backend-controlled gambling
    samples = []
    10.times do
      samples << VoluntarinessConstants::OBTAINABLE_ITEMS.sample
    end
    
    # Should have valid items
    samples.each do |item|
      assert_includes VoluntarinessConstants::OBTAINABLE_ITEMS, item
      assert_not_nil item[:name]
      assert_not_nil item[:svg]
    end
    
    # With 10 samples from 6 items, we should likely have some variation
    # (though this is probabilistic and could theoretically fail)
    unique_items = samples.uniq
    assert unique_items.length > 1, "Random sampling should produce some variation"
  end

  test "target angle calculation for wheel positioning" do
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    degrees_per_section = 360.0 / items.length
    
    items.each_with_index do |item, index|
      # Calculate expected target angle (center of section)
      expected_angle = index * degrees_per_section + (degrees_per_section / 2)
      
      # Verify angle is within valid range
      assert expected_angle >= 0, "Target angle should be non-negative"
      assert expected_angle < 360, "Target angle should be less than 360 degrees"
      
      # For 6 items, each section should be 60 degrees
      assert_equal 60.0, degrees_per_section, "Each section should be 60 degrees for 6 items"
      
      # First item should be at 30 degrees (center of first section)
      if index == 0
        assert_equal 30.0, expected_angle, "First item should target center of first section"
      end
    end
  end

  test "winning item index mapping to target angle" do
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    
    # Test that each item maps to correct angle
    items.each_with_index do |winning_item, expected_index|
      actual_index = items.index(winning_item)
      assert_equal expected_index, actual_index, "Item index should match expected position"
      
      # Calculate angle for this item
      degrees_per_section = 360.0 / items.length
      target_angle = actual_index * degrees_per_section + (degrees_per_section / 2)
      
      # Verify angle calculation
      expected_angles = [30.0, 90.0, 150.0, 210.0, 270.0, 330.0] # Centers of 6 sections
      assert_equal expected_angles[expected_index], target_angle, "Target angle should match expected value for item #{winning_item[:name]}"
    end
  end

  test "invalid item names are handled gracefully" do
    invalid_item = UseableItem.create_from_obtainable(@participant, "NonexistentItem")
    assert_nil invalid_item, "Should return nil for invalid item names"
  end

  test "data integrity after multiple gambling sessions" do
    initial_actions = @participant.actions.count
    initial_items = @participant.useable_items.count
    initial_points = @participant.total_points.to_f
    
    # Give participant enough points for multiple gambles
    3.times do
      Action.create!(participant: @participant, task: @task)
    end
    @participant.reload
    
    # Simulate 3 gambling sessions
    3.times do |i|
      # Deduct point
      gambling_task = Task.create!(
        user: @user,
        title: "Gamble Bet #{i + 1}",
        worth: -1
      )
      Action.create!(participant: @participant, task: gambling_task)
      
      # Win item
      item_data = VoluntarinessConstants::OBTAINABLE_ITEMS[i % VoluntarinessConstants::OBTAINABLE_ITEMS.length]
      UseableItem.create_from_obtainable(@participant, item_data[:name])
    end
    
    @participant.reload
    
    # Verify data integrity
    assert_equal initial_actions + 6, @participant.actions.count # 3 positive + 3 negative actions
    assert_equal initial_items + 3, @participant.useable_items.count
    
    # Verify point calculation is correct - should increase by the net change
    expected_points = initial_points + (3 * @task.worth) - 3 # 3 task completions minus 3 gambling bets
    assert_equal expected_points, @participant.total_points.to_f
  end
end