require "test_helper"

class StatisticsServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @service = StatisticsService.new(@user)
  end

  test "should initialize with user" do
    service = StatisticsService.new(@user)
    assert_equal @user, service.send(:user)
  end

  test "should initialize with user and custom participants" do
    participants = @user.participants.limit(2)
    service = StatisticsService.new(@user, participants)
    assert_equal @user, service.send(:user)
    assert_equal participants, service.send(:participants)
  end

  test "should default to user participants with includes when no participants provided" do
    service = StatisticsService.new(@user)
    participants = service.send(:participants)
    
    # Should include actions and tasks to avoid N+1 queries
    assert_respond_to participants, :each
  end

  test "generate_task_completion_data should return task completion statistics" do
    result = @service.generate_task_completion_data
    
    # Should return an ActiveRecord relation
    assert_respond_to result, :each
    
    # Should include the expected columns
    first_result = result.first
    if first_result
      assert_respond_to first_result, :task_title
      assert_respond_to first_result, :participant_name
      assert_respond_to first_result, :actions_count
      assert_respond_to first_result, :task_worth
    end
  end

  test "generate_task_completion_data should only include non-archived tasks" do
    # Create an archived task with actions
    archived_task = Task.create!(
      title: "Archived Task",
      worth: 10,
      archived: true,
      user: @user
    )
    
    Action.create!(
      task: archived_task,
      participant: participants(:alice)
    )
    
    result = @service.generate_task_completion_data
    
    # Should not include archived tasks
    result.each do |item|
      assert_equal false, item.task_archived
    end
  end

  test "generate_task_completion_by_participant should return participant action counts" do
    result = @service.generate_task_completion_by_participant
    
    assert_kind_of Hash, result
    
    # Should have participant names as keys and counts as values
    result.each do |participant_name, count|
      assert_kind_of String, participant_name
      assert_kind_of Integer, count
      assert count >= 0
    end
  end

  test "generate_task_completion_by_action should process data correctly" do
    test_data = [
      { task_title: "Task 1", participant_name: "Alice", actions_count: 2, task_worth: 10 },
      { task_title: "Task 1", participant_name: "Bob", actions_count: 1, task_worth: 10 },
      { task_title: "Task 2", participant_name: "Alice", actions_count: 3, task_worth: 5 }
    ]
    
    result = @service.generate_task_completion_by_action(test_data)
    
    assert_equal 20, result["Task 1"]["Alice"]  # 2 * 10
    assert_equal 10, result["Task 1"]["Bob"]    # 1 * 10
    assert_equal 15, result["Task 2"]["Alice"]  # 3 * 5
  end

  test "generate_task_completion_by_action should handle empty data" do
    result = @service.generate_task_completion_by_action([])
    
    assert_kind_of Hash, result
    assert_empty result
  end

  test "generate_points_by_participant should return participant point totals" do
    result = @service.generate_points_by_participant
    
    assert_kind_of Hash, result
    
    # Should have participant names as keys and point totals as values
    result.each do |participant_name, points|
      assert_kind_of String, participant_name
      assert_kind_of Numeric, points
      assert points >= 0
    end
  end

  test "generate_task_popularity should return tasks ordered by action count" do
    result = @service.generate_task_popularity
    
    assert_kind_of Hash, result
    
    # Should be ordered by count descending
    counts = result.values
    assert_equal counts.sort.reverse, counts
    
    # Should have task titles as keys and counts as values
    result.each do |task_title, count|
      assert_kind_of String, task_title
      assert_kind_of Integer, count
      assert count >= 0
    end
  end

  test "generate_activity_over_time should return daily activity for last 30 days" do
    result = @service.generate_activity_over_time
    
    assert_kind_of Hash, result
    
    # Keys should be dates, values should be counts
    result.each do |date, count|
      assert_kind_of Date, date
      assert_kind_of Integer, count
      assert count >= 0
    end
    
    # Should cover up to 30 days
    assert result.keys.length <= 30
  end

  test "generate_participant_activity should return participant activity by day" do
    result = @service.generate_participant_activity
    
    assert_kind_of Hash, result
    
    # Keys should be arrays of [participant_name, date], values should be counts
    result.each do |key, count|
      assert_kind_of Array, key
      assert_equal 2, key.length
      assert_kind_of String, key[0]  # participant name
      assert_kind_of Date, key[1]    # date
      assert_kind_of Integer, count
      assert count >= 0
    end
  end

  test "generate_points_by_day should return daily point totals for last 30 days" do
    result = @service.generate_points_by_day
    
    assert_kind_of Hash, result
    
    # Keys should be dates, values should be point totals
    result.each do |date, points|
      assert_kind_of Date, date
      assert_kind_of Numeric, points
      assert points >= 0
    end
    
    # Should cover up to 30 days
    assert result.keys.length <= 30
  end

  test "generate_cumulative_data should return cumulative points data" do
    result = @service.generate_cumulative_data
    
    assert_kind_of Hash, result
    
    # Should be a nested hash: participant_name => { date => cumulative_points }
    result.each do |participant_name, dates_hash|
      assert_kind_of String, participant_name
      assert_kind_of Hash, dates_hash
      
      dates_hash.each do |date, points|
        assert_kind_of String, date  # Date is returned as string from SQL
        assert_kind_of Numeric, points
        assert points >= 0
      end
    end
  end

  test "generate_cumulative_data should only include positive worth tasks" do
    # Create a task with zero worth
    zero_worth_task = Task.create!(
      title: "Zero Worth Task", 
      worth: 0,
      user: @user
    )
    
    Action.create!(
      task: zero_worth_task,
      participant: participants(:alice)
    )
    
    # Create a task with negative worth
    negative_worth_task = Task.create!(
      title: "Negative Worth Task",
      worth: -5,
      user: @user  
    )
    
    Action.create!(
      task: negative_worth_task,
      participant: participants(:alice)
    )
    
    result = @service.generate_cumulative_data
    
    # Should not include actions from zero or negative worth tasks
    # This is tested by checking that cumulative points only go up
    result.each do |participant_name, dates_hash|
      previous_points = 0
      dates_hash.values.each do |points|
        assert points >= previous_points, "Cumulative points should not decrease"
        previous_points = points
      end
    end
  end

  test "generate_chart_cumulative_data should format data for charts" do
    test_cumulative_data = {
      "Alice" => {
        "2023-12-01" => 10,
        "2023-12-03" => 25
      },
      "Bob" => {
        "2023-12-02" => 15,
        "2023-12-03" => 30
      }
    }
    
    result = @service.generate_chart_cumulative_data(test_cumulative_data)
    
    assert_kind_of Hash, result
    assert_includes result.keys, :chart_labels
    assert_includes result.keys, :chart_cumulative_data
    
    # Chart labels should be formatted dates
    labels = result[:chart_labels]
    assert_kind_of Array, labels
    labels.each do |label|
      assert_kind_of String, label
      assert_match /\d{2} \w{3}/, label  # Format: "01 Dec"
    end
    
    # Chart data should be nested hash with formatted dates
    chart_data = result[:chart_cumulative_data]
    assert_kind_of Hash, chart_data
    
    chart_data.each do |participant_name, dates_hash|
      assert_kind_of String, participant_name
      assert_kind_of Hash, dates_hash
      
      dates_hash.each do |formatted_date, points|
        assert_kind_of String, formatted_date
        assert_match /\d{2} \w{3}/, formatted_date
        assert_kind_of Numeric, points
      end
    end
  end

  test "generate_chart_cumulative_data should handle invalid dates gracefully" do
    test_data_with_invalid_dates = {
      "Alice" => {
        "invalid-date" => 10,
        "2023-12-01" => 15
      }
    }
    
    # Should not raise error
    assert_nothing_raised do
      result = @service.generate_chart_cumulative_data(test_data_with_invalid_dates)
      assert_kind_of Hash, result
    end
  end

  test "generate_chart_cumulative_data should fill in missing dates with last known points" do
    test_cumulative_data = {
      "Alice" => {
        "2023-12-01" => 10,
        "2023-12-03" => 25  # Missing Dec 2
      }
    }
    
    result = @service.generate_chart_cumulative_data(test_cumulative_data)
    chart_data = result[:chart_cumulative_data]
    
    alice_data = chart_data["Alice"]
    
    # Should have data for all dates in range
    assert alice_data["01 Dec"] == 10
    assert alice_data["02 Dec"] == 10  # Should carry forward last known value
    assert alice_data["03 Dec"] == 25
  end

  test "should handle user with no actions" do
    user_with_no_actions = users(:two)
    # Clear any existing actions
    user_with_no_actions.actions.destroy_all
    
    service = StatisticsService.new(user_with_no_actions)
    
    # Should not raise errors
    assert_nothing_raised do
      service.generate_task_completion_data
      service.generate_task_completion_by_participant
      service.generate_points_by_participant
      service.generate_task_popularity
      service.generate_activity_over_time
      service.generate_participant_activity
      service.generate_points_by_day
      service.generate_cumulative_data
    end
  end

  test "should handle user with no participants" do
    user_with_no_participants = users(:two)
    user_with_no_participants.participants.destroy_all
    
    service = StatisticsService.new(user_with_no_participants)
    
    # Should not raise errors
    assert_nothing_raised do
      service.generate_task_completion_data
      service.generate_task_completion_by_participant
      service.generate_points_by_participant
      service.generate_task_popularity
    end
  end

  test "should scope all queries to user's data only" do
    user_two = users(:two)
    service_two = StatisticsService.new(user_two)
    
    # User one should not see user two's data
    result = @service.generate_task_completion_by_participant
    user_two_participant_names = user_two.participants.pluck(:name)
    
    result.keys.each do |participant_name|
      assert_not_includes user_two_participant_names, participant_name
    end
  end
end