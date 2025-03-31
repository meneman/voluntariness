class ParticipantsController < ApplicationController
    before_action :set_participant, except: [ :index, :new, :create, :cancel ]

    def index
         @participants = current_user.participants.all()
         respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end


    def show
    end

    def new
        @participant = current_user.participants.build
    end

    def edit
    end

    def cancel
        respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end

    # def cancel
    # end
    def create
        @participant = current_user.participants.build(participant_params)

        if @participant.save
            respond_to do |format|
                format.html { }
                format.turbo_stream { }
            end
        else
            render :new, status: :unprocessable_entity
        end
    end

    def archive
        @participant.update(archived: !@participant.archived)
        respond_to do |format|
            format.html { }
            format.turbo_stream { }
        end
    end


    def update
        respond_to do |format|
          if @participant.update(participant_params)
            format.html { redirect_to action: "index", format: :html }

          else
            format.html { render :edit, status: :unprocessable_entity }
            format.turbo_stream { render :edit, status: :unprocessable_entity }
          end
        end
    end

    def update_points
        @participants = current_user.participans.active
        @participants.each do |p|
           points[p.id] = p.total_points
        end

        respond_to do |format|
            format.turbo_stream
        end
    end

    def destroy
        @participant.destroy()
        redirect_to :root
    end

    private

    def participant_params
        params.require(:participant).permit(:name, :color, :avatar)
    end

    def set_participant
        @participant = current_user.participants.find(params[:id])



    rescue ActiveRecord::RecordNotFound
        redirect_to root_path
    end
end
