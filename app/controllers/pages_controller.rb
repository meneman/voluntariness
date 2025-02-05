class PagesController < ApplicationController
    before_action :set_participants, except: [:home]
    before_action :set_tasks, except: [:home]

    def home     
        @participants = current_user.participants.active
        @tasks = current_user.tasks.active.ordered
        respond_to do |format|
            format.html {}
            format.turbo_stream {}
        end
    end

    def statistics
        @data = current_user.actions.joins(:task, :participant)
        .group('tasks.title', 'participants.name')
        .select('tasks.title AS task_title', 'participants.name AS participant_name', "tasks.archived AS task_archived", 'COUNT(actions.id) AS actions_count')
        # .where("task_archived = 0")
        .order('tasks.title', 'participants.name')
        @linedata = current_user.actions.joins(:participant)
        .group("participants.name", "DATE(actions.created_at)")
        .count
        respond_to do |format|
            format.html {}
            format.turbo_stream {}
        end
    end

    def set_tasks 
        @tasks =  params[:active] ?  current_user.tasks.active : current_user.tasks
    end

    def set_participants 
        @participants =  params[:active] ? current_user.participants.active : current_user.participants
    end 
end
