class PagesController < ApplicationController

    def home
       
        @participants = Participant.active
        @tasks = Task.all()
        respond_to do |format|
            format.turbo_stream { flash.now[:notice] = "Date was successfully destroyed." }
            format.html
        end
    end

    def statistics
        @participants = params[:active] ? Participant.active : Participant.all()
        @tasks = Task.all()
        @data = Action.joins(:task, :participant)
        .group('tasks.title', 'participants.name')
        .select('tasks.title AS task_title', 'participants.name AS participant_name', 'COUNT(actions.id) AS actions_count')
        .order('tasks.title', 'participants.name')
        @linedata = Action.joins(:participant)
        .group("participants.name", "DATE(actions.created_at)")
        .count
    end

    

    def blog_post_params 
        params.permit(:title, :content, :published_at)
    end
end
