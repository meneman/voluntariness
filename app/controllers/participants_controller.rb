class ParticipantsController < ApplicationController

          
    before_action :set_participant, except: [:index, :new, :create, :cancel]

    def index
         @participants = Participant.all()
    end

    
    def show
    end

    def new 
        @participant = Participant.new
    end

    def edit 
    end

    def cancel 
        respond_to do |format|
            format.html {}
            format.turbo_stream {}
        end
    end

    def cancel
    end
    def create 
        
        @participant = Participant.new(participant_params)
        
        if @participant.save
            respond_to do |format|
                format.html {}
                format.turbo_stream {}
            end
        else
            render :new, status: :unprocessable_entity
        end
    end

    def archive
        @participant.update(archived: !@participant.archived)
        respond_to do |format|
            format.html {}
            format.turbo_stream {}
        end
    end


    def update 
        if @participant.update(participant_params)
            redirect_to @participant
        else 
            render :edit, status: :unprocessable_entity
        end
    end

    def update_points
        @participants = Participant.active
        @points = {}
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
        @participant = Participant.find(params[:id]) 
    
        
        
    rescue ActiveRecord::RecordNotFound
        redirect_to root_path
    end 
    
end
