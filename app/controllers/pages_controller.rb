class PagesController < ApplicationController
    before_action :set_participants, except: [ :home ]
    before_action :set_tasks, except: [ :home ]

    def home
        @participants = current_user.participants.active
        @tasks = current_user.tasks.active.ordered
        respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end

    def statistics
        # Task completion per participant (for pie chart)
        #
        @data = current_user.actions.joins(:task, :participant)
        .group("tasks.title", "participants.name")
        .select("tasks.title AS task_title", "participants.name AS participant_name", "tasks.archived AS task_archived", "COUNT(actions.id) AS actions_count")
        .where("task_archived = 0")
        .order("tasks.title", "participants.name")

        @linedata = current_user.actions.joins(:participant)
        .group("participants.name", "DATE(actions.created_at)")

        @task_completion_by_participant = current_user.actions
            .joins(:participant)
            .group("participants.name")
            .count




        # Points per participant (for pie/bar chart)
        @points_by_participant = current_user.actions
            .joins(:task, :participant)
            .group("participants.name")
            .sum("tasks.worth")

        # Task popularity (for bar chart)
        @task_popularity = current_user.actions
            .joins(:task)
            .group("tasks.title")
            .count
            .sort_by { |_, count| -count }
            .to_h

        # Activity over time (for line chart)
        @activity_over_time = current_user.actions
            .group_by_day(:created_at, last: 30)
            .count

        # Activity by participant over time (for line chart)
        @participant_activity = current_user.actions
            .joins(:participant)
            .group("participants.name")
            .group_by_day(:created_at, last: 30)
            .count

        # Worth completed by day (for bar chart)
        @points_by_day = current_user.actions
            .joins(:task)
            .group_by_day(:created_at, last: 30)
            .sum("tasks.worth")

        respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end

    def user_settings
        @settings = current_user.settings || current_user.build_settings

        respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end

    def set_tasks
        @tasks =  params[:active] ?  current_user.tasks.active : current_user.tasks
    end

    def set_participants
        @participants =  params[:active] ? current_user.participants.active : current_user.participants
    end
end
