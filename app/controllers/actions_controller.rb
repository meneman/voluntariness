class ActionsController < ApplicationController
    before_action :set_action, except: [ :index, :new, :create ]

    def index
        @pagy, @actions = pagy(current_user.actions, {})
    end

    def show
    end

    def new
        @action = Action.new
        respond_to do |format|
            format.html
        end
    end

    def edit
    end

    def create
        return redirect_to root_path, alert: t("flash.missing_required_data") unless params[:data]

        participant = current_user.participants.find(params[:data][:participant_id])
        @task = current_user.tasks.find(params[:data][:task_id])

        @action = Action.new(participant_id: participant.id, task_id: @task.id)

        if @action.save
            respond_to do |format|
                format.html { redirect_to root_path, notice: t("flash.quote_created") }
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
        if params[:action].present? && params[:action].respond_to?(:permit)
            params.require(:action).permit(:task_id, :participant_id, :on_streak)
        else
            {}
        end
    end

    def set_action
        @action = current_user.actions.find(params[:id])
    end
end
