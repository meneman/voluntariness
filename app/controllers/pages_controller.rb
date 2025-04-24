# app/controllers/pages_controller.rb
class PagesController < ApplicationController
    # --- Filters ---

    # Set @participants and @tasks instance variables for most actions,
    # loading either all or only active ones based on params[:active].
    # Excludes the :home action as it has specific loading logic.
    before_action :set_participants, except: [ :home ]
    before_action :set_tasks, except: [ :home ]

    # --- Actions ---

    # GET /
    # Displays the main dashboard/home page.
    # Loads active participants and ordered active tasks specific to the home view.
    def home
      @participants = current_user.participants.active
      @tasks = current_user.tasks.active.ordered

      respond_to do |format|
        format.html { }         # Renders views/pages/home.html.erb
        format.turbo_stream { } # Renders views/pages/home.turbo_stream.erb
      end
    end

    # GET /statistics
    # Gathers various data points for displaying charts and statistics.
    def statistics
      # --- Data Gathering for Charts ---

      # Base data for task completion by participant (used for detailed breakdown)
      # Groups actions by task title and participant name, counting occurrences.
      # Filters out archived tasks.
      @data = current_user.actions
        .joins(:task, :participant)
        .group("tasks.title", "participants.name")
        .select(
          "tasks.title AS task_title",
          "participants.name AS participant_name",
          "tasks.archived AS task_archived",
          "COUNT(actions.id) AS actions_count",
          "tasks.worth AS task_worth"
        )
        .where("task_archived = 0")
        .order("tasks.title", "participants.name")

      # Simple count of actions per participant (e.g., for a pie chart)
      @task_completion_by_participant = current_user.actions
        .joins(:participant)
        .group("participants.name")
        .count

      # Calculate total points per task per participant
      # Structure: { "Task Title" => { "Participant Name" => total_points } }
      @task_completion_by_action = Hash.new { |h, k| h[k] = {} }
      @data.each do |item|
        task_title = item[:task_title]
        participant_name = item[:participant_name]
        points = item[:actions_count] * item[:task_worth]
        @task_completion_by_action[task_title][participant_name] = points
      end

      # Total points accumulated by each participant (e.g., for pie/bar chart)
      @points_by_participant = current_user.actions
        .joins(:task, :participant)
        .group("participants.name")
        .sum("tasks.worth")

      # Count of how many times each task was performed (e.g., for bar chart)
      # Sorted by popularity (most performed first).
      @task_popularity = current_user.actions
        .joins(:task)
        .group("tasks.title")
        .count
        .sort_by { |_, count| -count } # Sort descending by count
        .to_h

      # Total actions performed per day over the last 30 days (e.g., for line chart)
      @activity_over_time = current_user.actions
        .group_by_day(:created_at, last: 30)
        .count

      # Actions performed per participant per day over the last 30 days (e.g., for multi-line chart)
      # Structure: { ["Participant Name", Date] => count }
      @participant_activity = current_user.actions
        .joins(:participant)
        .group("participants.name")
        .group_by_day(:created_at, last: 30)
        .count

      # Total points worth of tasks completed per day over the last 30 days (e.g., for bar chart)
      @points_by_day = current_user.actions
        .joins(:task)
        .group_by_day(:created_at, last: 30)
        .sum("tasks.worth")

      # --- Cumulative Points Calculation (using SQL Window Function) ---

      # SQL query to calculate the running total (cumulative sum) of points
      # for each participant, ordered by date.
      select_cumulative_sql = <<-SQL.squish
        DISTINCT
        participants.name AS participant_name,
        DATE(actions.created_at) AS action_date,
        SUM(tasks.worth) OVER (
          PARTITION BY participants.name
          ORDER BY DATE(actions.created_at)
          ROWS UNBOUNDED PRECEDING
        ) AS cumulative_points
      SQL
      # Note: ROWS UNBOUNDED PRECEDING is standard for running totals,
      # ensuring the sum includes all rows from the start of the partition
      # up to the current row for each participant.

      # Execute the query to get cumulative points per participant per day
      cumulative_data = current_user.actions
        .joins(:task, :participant)
        .select(select_cumulative_sql)
        .where("tasks.worth > 0") # Only include actions linked to tasks with points
        .order("participant_name", "action_date") # Order for predictable results

      # Process raw cumulative data into a nested hash:
      # { "Participant Name" => { "YYYY-MM-DD" => cumulative_points } }
      @cumulative_points_by_participant_day = Hash.new { |h, k| h[k] = {} }
      cumulative_data.each do |record|
        date_key = record.action_date # Keep as string key from SQL
        @cumulative_points_by_participant_day[record.participant_name][date_key] =
          record.cumulative_points
      end

      # --- Prepare Data for Cumulative Chart ---

      # 1. Get all unique dates present in the cumulative data, sorted.
      all_dates = @cumulative_points_by_participant_day.values
        .flat_map(&:keys)
        .uniq
        .map { |d_str| Date.parse(d_str) rescue d_str } # Parse if possible
        .sort

      # Store formatted date labels (e.g., "24 Apr") for the chart's X-axis
      @chart_labels = all_dates.map { |date| date.strftime("%d %b") }

      # 2. Create the final data structure for the chart, filling in missing dates
      #    for each participant with their last known cumulative score.
      # Structure: { "Participant Name" => { "DD Mon" => cumulative_points } }
      @chart_cumulative_data = Hash.new { |h, k| h[k] = {} }
      last_known_points = Hash.new(0) # Track last score per participant

      # Assuming @participants is loaded (e.g., active participants)
      # If not loaded elsewhere, uncomment the next line:
      # @participants ||= current_user.participants.active.order(:name)

      @participants.each do |participant|
        participant_name = participant.name
        last_known_points[participant_name] = 0 # Reset for each participant
        participant_data = @cumulative_points_by_participant_day[participant_name] || {}

        all_dates.each do |date|
          date_key = date.is_a?(Date) ? date.to_s : date # Match original string key
          formatted_date = date.strftime("%d %b")       # Key for the final chart data

          # If there's data for this specific date, update the last known points
          if participant_data.key?(date_key)
            last_known_points[participant_name] = participant_data[date_key]
          end

          # Store the current cumulative value (either updated or carried forward)
          @chart_cumulative_data[participant_name][formatted_date] =
            last_known_points[participant_name]
        end
      end

      # Respond to request format
      respond_to do |format|
        format.html { }         # Renders views/pages/statistics.html.erb
        format.turbo_stream { } # Renders views/pages/statistics.turbo_stream.erb
      end
    end

    # GET /user_settings
    # Displays the settings page for the current user.
    # Loads existing settings or builds a new settings object if none exist.
    def user_settings
      @settings = current_user.settings || current_user.build_settings

      respond_to do |format|
        format.html { }         # Renders views/pages/user_settings.html.erb
        format.turbo_stream { } # Renders views/pages/user_settings.turbo_stream.erb
      end
    end

    # --- Private Methods ---

    private

    # Sets the @tasks instance variable based on the :active parameter.
    # Loads only active tasks if params[:active] is present and truthy,
    # otherwise loads all tasks for the current user.
    def set_tasks
      @tasks = if params[:active]
        current_user.tasks.active
      else
        current_user.tasks
      end
    end

    # Sets the @participants instance variable based on the :active parameter.
    # Loads only active participants if params[:active] is present and truthy,
    # otherwise loads all participants for the current user.
    def set_participants
      @participants = if params[:active]
        current_user.participants.active
      else
        current_user.participants
      end
      # Ensure @participants is loaded if needed for cumulative chart when :active is not set
      @participants ||= current_user.participants.order(:name) if defined?(@chart_cumulative_data)
    end
end
