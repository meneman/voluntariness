class ActionsController < ApplicationController

              
    before_action :set_participant, except: [:index, :new, :create]

    def index
         @actions = Action.all()
    end

    def show
    end

    def new 
        @action = Action.new
    end

    def edit 
      
    end

    def create 
        puts params.inspect
        @action = Action.new(participant_id: params[:data][:participant_id],task_id: params[:data][:task_id], )
        
        if @action.save
            respond_to do |format| 
                format.html
                format.turbo_stream
            end
        else
            render :new, status: :unprocessable_entity
        end
    end

    def update 

        if @action.update(participant_params)
            redirect_to @action
        else 
            render :edit, status: :unprocessable_entity
        end
    end


    def destroy 
        @action.destroy()
        redirect_to :root
    end

    private
    
    def participant_params 
        params.require(:action).permit(:task, :participant,:data)
    end

    def set_participant
        @action = Action.find(params[:id]) 
        
        
    rescue ActiveRecord::RecordNotFound
        redirect_to root_path
    end 
    
end
