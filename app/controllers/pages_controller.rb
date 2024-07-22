class PagesController < ApplicationController


    before_action :set_participants, except: [:landing]
    before_action :set_tasks, except: [:landing]


    def landing 
                  
    end
    def home       
        # @participants = current_user.participants.active
        # @tasks = current_user.tasks.active
        respond_to do |format|
            format.turbo_stream { flash.now[:notice] = "Date was successfully destroyed." }
            format.html
        end
    end

    def statistics

        @data = current_user.actions.joins(:task, :participant)
        .group('tasks.title', 'participants.name')
        .select('tasks.title AS task_title', 'participants.name AS participant_name', 'COUNT(actions.id) AS actions_count')
        .order('tasks.title', 'participants.name')
        @linedata = current_user.actions.joins(:participant)
        .group("participants.name", "DATE(actions.created_at)")
        .count
    end

    

    def blog_post_params 
        params.permit(:title, :content, :published_at)
    end

    def set_tasks 
        @tasks =  params[:active] ?  current_user.tasks.active : current_user.tasks
    end
    def set_participants 
        @participants =  params[:active] ? current_user.participants.active : current_user.participants
    end 
end
