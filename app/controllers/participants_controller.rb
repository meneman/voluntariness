class ParticipantsController < ApplicationController
    before_action :set_participant, except: [ :index, :new, :create, :cancel ]

    def index
         @participants = current_household.participants.all()
         respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end


    def show
    end

    def new
        @participant = current_household.participants.build
    end

    def edit
    end

    def cancel
        respond_to do |format|
            format.turbo_stream { }
        end
    end

    def create
        @participant = current_household.participants.build(participant_params)

        if @participant.save
            # Track participant creation
            PosthogService.track(current_user.id, 'participant_created', {
                participant_name: @participant.name,
                participant_color: @participant.color,
                household_id: current_household.id,
                household_name: current_household.name,
                total_participants: current_household.participants.count
            })
            
            respond_to do |format|
                format.html { redirect_to participants_path, notice: t("flash.participant_created") }
                format.turbo_stream { }
            end
        else
            render :new, status: :unprocessable_entity
        end
    end

    def archive
        @participant.update(archived: true)
        respond_to do |format|
            format.html { redirect_to participants_path }
            format.turbo_stream { }
        end
    end

    def unarchive
        @participant.update(archived: false)
        respond_to do |format|
            format.html { redirect_to participants_path }
            format.turbo_stream { }
        end
    end


    def update
        respond_to do |format|
          if @participant.update(participant_params)
            format.html { redirect_to participants_path }
            format.turbo_stream { }
          else
            format.html { render :edit, status: :unprocessable_entity }
            format.turbo_stream { render :edit, status: :unprocessable_entity }
          end
        end
    end

    def destroy
        @participant.destroy()
        respond_to do |format|
            format.html { redirect_to pages_home_path, notice: t("flash.participant_deleted") }
            format.turbo_stream { flash.now[:notice] = t("flash.participant_deleted") }
        end
    end

    private

    def participant_params
        params.require(:participant).permit(:name, :color, :avatar)
    end

    def set_participant
        @participant = current_household.participants.find(params[:id])
    end
end
