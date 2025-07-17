class ActionParticipant < ApplicationRecord
  belongs_to :action
  belongs_to :participant

  validates :action_id, uniqueness: { scope: :participant_id }
  validates :points_earned, presence: true, numericality: true
  validates :bonus_points, numericality: true

  after_create_commit { broadcast_total_points }
  after_destroy_commit { broadcast_total_points }

  after_create :update_streak_status!

  def update_streak_status!
    participant.update_streak!
    
    # Update on_streak based on the participant's new streak status
    update!(on_streak: participant.on_streak)
  end

  private

  def broadcast_total_points
    return unless participant_id && Participant.exists?(participant_id)
    participant.reload # Ensure we have fresh data
    
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
end