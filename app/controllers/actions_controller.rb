class ActionsController < ApplicationController
    before_action :set_participant, except: [ :index, :new, :create ]

    def index
        @pagy, @actions = pagy(current_user.actions, {})
    end

    def show
    end

    def new
        @action = Action.new
        respond_to do |format|
            format.html
            format.turbo_stream
        end
    end

    def edit
    end

    def create
        return redirect_to root_path, alert: 'Missing required data' unless params[:data]
        
        participant = current_user.participants.find(params[:data][:participant_id])
        @task = current_user.tasks.find(params[:data][:task_id])
        
        on_streak = participant.on_streak
        @action = Action.new(participant_id: participant.id, task_id: @task.id, on_streak: on_streak)

        if @action.save
            respond_to do |format|
                format.html { redirect_to root_path, notice: "Quote was successfully created." }
                format.turbo_stream { flash.now[:action_flash] = @action }#  {participant: @action.participant, task: @action.task} }
            end
        else
            render :new, status: :unprocessable_entity
        end
    end

    def update
        if @action.update(action_params)
            redirect_to @action
        else
            render :edit, status: :unprocessable_entity
        end
    end

    def destroy
        @action.destroy()
        respond_to do |format|
            format.html
            format.turbo_stream
          end
    end

    private

    def action_params
        params.require(:action).permit(:task, :participant, :data)
    end

    def set_participant
        @action = Action.find(params[:id])


    rescue ActiveRecord::RecordNotFound
        redirect_to root_path
    end
end
