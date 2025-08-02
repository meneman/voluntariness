# app/controllers/pages_controller.rb
class PagesController < ApplicationController
    # --- Filters ---

    # Skip authentication for public pages
    skip_before_action :authenticate_user!, only: [ :pricing ]

    # Set @participants and @tasks instance variables for most actions,
    # loading either all or only active ones based on params[:active].
    # Excludes the :home action as it has specific loading logic.
    before_action :set_participants, except: [ :home, :pricing, :chatgpt_data ]
    before_action :set_tasks, except: [ :home, :pricing, :chatgpt_data ]

    # --- Actions ---

    # GET /
    # Displays the main dashboard/home page.
    # Loads active participants and ordered active tasks specific to the home view.
    def home
      # Eager load associations to prevent N+1 queries
      @participants = current_household.participants.active.includes(actions: :task)
      @tasks = current_household.tasks.active.ordered.includes(:actions)

      respond_to do |format|
        format.html { }         # Renders views/pages/home.html.erb
        format.turbo_stream { } # Renders views/pages/home.turbo_stream.erb
      end
    end

    # GET /statistics
    # Gathers various data points for displaying charts and statistics.
    def statistics
      # Get interval parameter from query string (1week, 1month, 1year, all)
      interval = params[:interval]
      start_date = params[:start_date]
      end_date = params[:end_date]

      # Use StatisticsService to handle complex data generation
      service = StatisticsService.new(current_household, @participants, interval, start_date, end_date)

      @data = service.generate_task_completion_data
      @task_completion_by_participant = service.generate_task_completion_by_participant
      @task_completion_by_action = service.generate_task_completion_by_action(@data)
      @points_by_participant = service.generate_points_by_participant
      @task_popularity = service.generate_task_popularity
      @activity_over_time = service.generate_activity_over_time
      @participant_activity = service.generate_participant_activity
      @points_by_day = service.generate_points_by_day

      # Cumulative data generation
      @cumulative_points_by_participant_day = service.generate_cumulative_data
      chart_data = service.generate_chart_cumulative_data(@cumulative_points_by_participant_day)
      @chart_labels = chart_data[:chart_labels]
      @chart_cumulative_data = chart_data[:chart_cumulative_data]

      # Bonus points data
      @bonus_points_by_day = service.generate_bonus_points_by_day
      @cumulative_bonus_by_participant_day = service.generate_cumulative_bonus_data
      bonus_chart_data = service.generate_chart_cumulative_data(@cumulative_bonus_by_participant_day)
      @bonus_chart_labels = bonus_chart_data[:chart_labels]
      @bonus_chart_cumulative_data = bonus_chart_data[:chart_cumulative_data]

      respond_to do |format|
        format.html { }
        format.turbo_stream { }
      end
    end

    # GET /user_settings
    # Displays the settings page for the current user.
    # Loads existing settings or builds a new settings object if none exist.
    def settings
      # @settings = current_user.settings ||

      respond_to do |format|
        format.html { }         # Renders views/pages/user_settings.html.erb
        format.turbo_stream { } # Renders views/pages/user_settings.turbo_stream.erb
      end
    end

    # GET /gambling
    # Displays the spinning wheel gambling/game page.
    def gambling
      respond_to do |format|
        format.html { }         # Renders views/pages/gambling.html.erb
        format.turbo_stream { } # Renders views/pages/gambling.turbo_stream.erb if needed
      end
    end

    # GET /pricing
    # Displays the pricing page with subscription tiers.
    def pricing
      respond_to do |format|
        format.html { render layout: "landing" }         # Renders views/pages/pricing.html.erb
        format.turbo_stream { } # Renders views/pages/pricing.turbo_stream.erb if needed
      end
    end

    # GET /chatgpt_data
    # Displays the ChatGPT prompt data for household analysis
    def chatgpt_data
      begin
        @chatgpt_prompt = ChatGptPromptService.new(current_household).generate_prompt
      rescue StandardError => e
        Rails.logger.error "ChatGPT prompt generation failed: #{e.message}"
        @chatgpt_prompt = "Error generating ChatGPT prompt. Please try again later."
        flash.now[:alert] = "Unable to generate analysis data at this time."
      end

      respond_to do |format|
        format.html { }         # Renders views/pages/chatgpt_data.html.erb
        format.turbo_stream { } # Renders views/pages/chatgpt_data.turbo_stream.erb if needed
      end
    end

    # --- Private Methods ---

    private

    # Sets the @tasks instance variable based on the :active parameter.
    # Loads only active tasks if params[:active] is present and truthy,
    # otherwise loads all tasks for the current user.
    def set_tasks
      @tasks = if params[:active]
        current_household.tasks.active
      else
        current_household.tasks
      end
    end

    # Sets the @participants instance variable based on the :active parameter.
    # Loads only active participants if params[:active] is present and truthy,
    # otherwise loads all participants for the current user.
    def set_participants
      # Eager load associations to prevent N+1 queries
      @participants = if params[:active]
        current_household.participants.active.includes(actions: :task)
      else
        current_household.participants.includes(actions: :task)
      end
      # Ensure @participants is loaded if needed for cumulative chart when :active is not set
      @participants ||= current_household.participants.includes(actions: :task).order(:name) if defined?(@chart_cumulative_data)
    end
end
