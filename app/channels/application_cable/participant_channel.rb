class ParticipantChannel < ApplicationCable::Channel
    def subscribed
      participant = Participant.find(params[:id])
      stream_for participant
    end
  
    def unsubscribed
      # Any cleanup needed when channel is unsubscribed
    end
  end