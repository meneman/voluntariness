class ActionParticipant < ApplicationRecord
  include ParticipantPointsBroadcaster
  
  belongs_to :action
  belongs_to :participant

  validates :action_id, uniqueness: { scope: :participant_id }
  validates :points_earned, presence: true, numericality: true
  validates :bonus_points, numericality: true

  after_create_commit { broadcast_participant_points(participant) }
  after_destroy_commit { broadcast_participant_points(participant) }

  after_create :update_streak_status!

  def update_streak_status!
    participant.update_streak!
    # Update on_streak based on the participant's new streak status
    update!(on_streak: participant.on_streak)
  end

end
