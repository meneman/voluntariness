class DefaultTasksService
  class ConfigurationError < StandardError; end

  def self.create_default_tasks_for(household)
    new.create_default_tasks_for(household)
  end

  def initialize
    @config_path = Rails.root.join("config", "default_tasks.yml")
  end

  def create_default_tasks_for(household)
    return false unless household.persisted?

    default_tasks_data = load_default_tasks
    return false if default_tasks_data.empty?

    Task.transaction do
      default_tasks_data.each_with_index do |task_data, index|
        Task.create!(
          household: household,
          title: translate_task_field(task_data, "title"),
          worth: task_data["worth"],
          interval: task_data["interval"],
          description: translate_task_field(task_data, "description"),
          position: index + 1,
          archived: false
        )
      end
    end

    Rails.logger.info "Created #{default_tasks_data.size} default tasks for household #{household.id}"
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create default tasks for household #{household.id}: #{e.message}"
    false
  end

  def load_default_tasks
    unless File.exist?(@config_path)
      Rails.logger.warn "Default tasks configuration file not found at #{@config_path}"
      return []
    end

    config = YAML.load_file(@config_path)
    tasks = config["default_tasks"] || []

    # Validate task structure
    tasks.each do |task|
      validate_task_data(task)
    end

    tasks
  rescue Psych::SyntaxError => e
    Rails.logger.error "Invalid YAML in default tasks configuration: #{e.message}"
    raise ConfigurationError, "Invalid YAML in default tasks configuration: #{e.message}"
  rescue => e
    Rails.logger.error "Error loading default tasks configuration: #{e.message}"
    raise ConfigurationError, "Error loading default tasks configuration: #{e.message}"
  end

  private

  def validate_task_data(task_data)
    required_fields = %w[title worth interval description title_key description_key]
    missing_fields = required_fields.reject { |field| task_data.key?(field) }

    if missing_fields.any?
      raise ConfigurationError, "Task missing required fields: #{missing_fields.join(', ')}"
    end

    unless task_data["worth"].is_a?(Integer) && task_data["worth"] > 0
      raise ConfigurationError, "Task 'worth' must be a positive integer"
    end

    unless (task_data["interval"].is_a?(Integer) && task_data["interval"] > 0) || task_data["interval"].nil?
      raise ConfigurationError, "Task 'interval' must be a positive integer"
    end

    unless task_data["title"].is_a?(String) && task_data["title"].strip.present?
      raise ConfigurationError, "Task 'title' must be a non-empty string"
    end

    unless task_data["title_key"].is_a?(String) && task_data["title_key"].strip.present?
      raise ConfigurationError, "Task 'title_key' must be a non-empty string"
    end

    unless task_data["description_key"].is_a?(String) && task_data["description_key"].strip.present?
      raise ConfigurationError, "Task 'description_key' must be a non-empty string"
    end
  end

  def translate_task_field(task_data, field)
    key_field = "#{field}_key"
    i18n_key = "default_tasks.#{task_data[key_field]}.#{field}"

    # Try to get the translation, fallback to the original value if not found
    I18n.t(i18n_key, default: task_data[field])
  end
end
