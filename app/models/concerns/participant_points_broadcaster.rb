module ParticipantPointsBroadcaster
  extend ActiveSupport::Concern

  private

  def broadcast_participant_points(participant)
    return unless participant&.persisted?
    
    participant.reload # Ensure fresh data
    
    broadcast_replace_to "participants_points",
      target: "points_for_#{participant.id}",
      partial: "pages/points",
      locals: {
        animate: true,
        id: participant.id,
        total_points: participant.total_points,
        base_points: participant.base_points,
        bonus_points_total: participant.bonus_points_total
      }

    broadcast_replace_to "participants_points",
      target: "bonus_points_for_#{participant.id}",
      partial: "participants/bonus_points",
      locals: {
        id: participant.id,
        bonus_points_total: participant.bonus_points_total
      }
  end

  def broadcast_multiple_participants_points(participants)
    participants.find_each do |participant|
      broadcast_participant_points(participant)
    end
  end
end