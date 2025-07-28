class ActionsController < ApplicationController
    before_action :set_action, except: [ :index, :new, :create ]

    def index
        @pagy, @actions = pagy(current_household.actions.distinct, {})
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

        # Find task safely
        @task = current_household.tasks.find_by(id: params[:data][:task_id])
        return redirect_to root_path, alert: t("flash.invalid_participants") unless @task
        
        participant_ids = Array(params[:data][:participant_ids] || params[:data][:participant_id]).compact.reject(&:blank?)
        
        # Check if we have any participants
        return redirect_to root_path, alert: t("flash.invalid_participants") if participant_ids.empty?
        
        # Validate all participants belong to current household
        participants = current_household.participants.where(id: participant_ids)
        return redirect_to root_path, alert: t("flash.invalid_participants") if participants.count != participant_ids.count

        # Calculate bonus points before saving the action
        bonus_points = @task.calculate_bonus_points
        
        @action = Action.new(task_id: @task.id)

        if @action.save
            @action.add_participants(participant_ids, bonus_points: bonus_points)
            
            # Track task completion in PostHog
            user_total_completed_tasks = current_user.households.joins(participants: :actions).count
            is_first_task = user_total_completed_tasks == 1
            
            participants.each do |participant|
                PosthogService.track(current_user.id, 'task_completed', {
                    task_id: @task.id,
                    task_title: @task.title,
                    task_worth: @task.worth,
                    task_interval: @task.interval,
                    participant_id: participant.id,
                    participant_name: participant.name,
                    bonus_points: bonus_points,
                    household_id: current_household.id,
                    total_participants: participants.count,
                    is_first_task: is_first_task
                })
            end
            
            # Track first task completion milestone
            if is_first_task
                PosthogService.track(current_user.id, 'first_task_completed', {
                    task_title: @task.title,
                    task_worth: @task.worth,
                    days_since_signup: (Time.current - current_user.created_at) / 1.day,
                    participant_name: participants.first.name
                })
            end
            
            respond_to do |format|
                format.html { redirect_to root_path, notice: t("flash.quote_created") }
                format.turbo_stream { flash.now[:action_flash] = @action }
            end
        else
            respond_to do |format|
                format.html { render :new, status: :unprocessable_entity }
                format.turbo_stream { render :new, status: :unprocessable_entity }
            end
        end
    end

    def add_participant
        unless params[:participant_id]
            respond_to do |format|
                format.turbo_stream { render plain: "Missing participant_id", status: :bad_request }
                format.html { redirect_to root_path, alert: "Missing participant_id" }
            end
            return
        end
        
        participant_id = params[:participant_id]
        
        # Validate participant belongs to current household
        @participant = current_household.participants.find_by(id: participant_id)
        unless @participant
            respond_to do |format|
                format.turbo_stream { render plain: "Invalid participant", status: :bad_request }
                format.html { redirect_to root_path, alert: "Invalid participant" }
            end
            return
        end
        
        # Check if participant is already in this action
        if @action.participants.exists?(id: participant_id)
            respond_to do |format|
                format.turbo_stream { render plain: "Participant already added", status: :unprocessable_entity }
                format.html { redirect_to root_path, alert: "Participant already added" }
            end
            return
        end
        
        # Add participant to existing action
        @action.add_participants([participant_id])
        @task = @action.task
        
        respond_to do |format|
            format.turbo_stream { flash.now[:action_flash] = @action }
            format.html { redirect_to root_path, notice: "#{@participant.name} added to task" }
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
            params.require(:action).permit(:task_id, participant_ids: [])
        else
            {}
        end
    end

    def set_action
        @action = Action.joins(action_participants: :participant)
                        .where(participants: { household_id: current_household.id })
                        .find(params[:id])
    end
end
