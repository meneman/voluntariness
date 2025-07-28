require "test_helper"
require "minitest/mock"

class DefaultTasksServiceTest < ActiveSupport::TestCase
  def setup
    @household = households(:one)
    @service = DefaultTasksService.new
  end

  test "should create default tasks for household" do
    # Clear any existing tasks
    @household.tasks.destroy_all

    assert_difference "@household.tasks.count", 8 do
      result = DefaultTasksService.create_default_tasks_for(@household)
      assert result
    end

    # Verify tasks were created with correct attributes
    tasks = @household.tasks.ordered
    assert_equal "Dishes", tasks.first.title
    assert_equal 1, tasks.first.worth
    assert_nil tasks.first.interval
    assert_equal "Wash dishes and clean kitchen", tasks.first.description
    assert_equal false, tasks.first.archived

    assert_equal "Take out trash", tasks.second.title
    assert_equal 1, tasks.second.worth
    assert_equal 3, tasks.second.interval
  end

  test "should handle non-persisted household" do
    non_persisted_household = Household.new(name: "Test")

    assert_no_difference "Task.count" do
      result = DefaultTasksService.create_default_tasks_for(non_persisted_household)
      assert_not result
    end
  end

  test "should load default tasks from YAML" do
    tasks = @service.load_default_tasks

    assert_not_empty tasks
    assert_equal 8, tasks.size

    first_task = tasks.first
    assert_equal "Dishes", first_task["title"]
    assert_equal "dishes", first_task["title_key"]
    assert_equal 1, first_task["worth"]
    assert_nil first_task["interval"]
    assert_equal "Wash dishes and clean kitchen", first_task["description"]
    assert_equal "dishes", first_task["description_key"]
  end

  test "should handle missing configuration file" do
    service = DefaultTasksService.new
    service.instance_variable_set(:@config_path, Rails.root.join("config", "nonexistent.yml"))

    tasks = service.load_default_tasks
    assert_empty tasks
  end

  test "should validate required fields" do
    # Create a temporary config file with invalid data
    temp_config_path = Rails.root.join("tmp", "test_invalid_tasks.yml")
    invalid_config = {
      "default_tasks" => [
        {
          "title" => "Invalid Task",
          "worth" => "not_a_number", # Invalid worth
          "interval" => 1,
          "description" => "Test"
        }
      ]
    }

    File.write(temp_config_path, invalid_config.to_yaml)

    service = DefaultTasksService.new
    service.instance_variable_set(:@config_path, temp_config_path)

    assert_raises(DefaultTasksService::ConfigurationError) do
      service.load_default_tasks
    end

    # Clean up
    File.delete(temp_config_path) if File.exist?(temp_config_path)
  end

  test "should validate missing required fields" do
    # Create a temporary config file with missing fields
    temp_config_path = Rails.root.join("tmp", "test_missing_fields.yml")
    invalid_config = {
      "default_tasks" => [
        {
          "title" => "Incomplete Task",
          "worth" => 5
          # Missing interval and description
        }
      ]
    }

    File.write(temp_config_path, invalid_config.to_yaml)

    service = DefaultTasksService.new
    service.instance_variable_set(:@config_path, temp_config_path)

    assert_raises(DefaultTasksService::ConfigurationError) do
      service.load_default_tasks
    end

    # Clean up
    File.delete(temp_config_path) if File.exist?(temp_config_path)
  end

  test "should handle invalid YAML syntax" do
    # Create a temporary config file with invalid YAML
    temp_config_path = Rails.root.join("tmp", "test_invalid_yaml.yml")
    File.write(temp_config_path, "invalid: yaml: content: [")

    service = DefaultTasksService.new
    service.instance_variable_set(:@config_path, temp_config_path)

    assert_raises(DefaultTasksService::ConfigurationError) do
      service.load_default_tasks
    end

    # Clean up
    File.delete(temp_config_path) if File.exist?(temp_config_path)
  end

  test "should return false on invalid task data" do
    @household.tasks.destroy_all
    initial_count = @household.tasks.count

    # Test with invalid household (simulating an error condition)
    invalid_household = Household.new # unpersisted household
    result = DefaultTasksService.create_default_tasks_for(invalid_household)
    assert_not result

    assert_equal initial_count, @household.tasks.count
  end

  test "should set correct positions for tasks" do
    @household.tasks.destroy_all

    DefaultTasksService.create_default_tasks_for(@household)

    tasks = @household.tasks.ordered
    tasks.each_with_index do |task, index|
      assert_equal index + 1, task.position
    end
  end

  test "should use i18n translations with fallback" do
    @household.tasks.destroy_all

    # Mock I18n to return a translation for one key and fallback for another
    original_method = I18n.method(:t)
    I18n.define_singleton_method(:t) do |key, options = {}|
      if key == "default_tasks.dishes.title"
        "Translated Dishes Title"
      else
        options[:default] || original_method.call(key, options)
      end
    end

    begin
      DefaultTasksService.create_default_tasks_for(@household)

      tasks = @household.tasks.ordered
      dishes_task = tasks.first

      # Should use translation for dishes title
      assert_equal "Translated Dishes Title", dishes_task.title
      # Should fallback to default for description
      assert_equal "Wash dishes and clean kitchen", dishes_task.description
    ensure
      # Restore original method
      I18n.define_singleton_method(:t, original_method)
    end
  end

  test "should validate required i18n keys" do
    # Create a temporary config file missing i18n keys
    temp_config_path = Rails.root.join("tmp", "test_missing_i18n_keys.yml")
    invalid_config = {
      "default_tasks" => [
        {
          "title" => "Test Task",
          "worth" => 5,
          "interval" => 1,
          "description" => "Test description"
          # Missing title_key and description_key
        }
      ]
    }

    File.write(temp_config_path, invalid_config.to_yaml)

    service = DefaultTasksService.new
    service.instance_variable_set(:@config_path, temp_config_path)

    assert_raises(DefaultTasksService::ConfigurationError) do
      service.load_default_tasks
    end

    # Clean up
    File.delete(temp_config_path) if File.exist?(temp_config_path)
  end
end
