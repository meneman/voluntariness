class Action < ApplicationRecord
  belongs_to :task
  belongs_to :participant

  scope :last_five_days, -> { where(created_at: VoluntarinessConstants::STREAK_CALCULATION_DAYS.days.ago.beginning_of_day..Time.now.end_of_day) }
  scope :desc, ->  { order(id: :desc) }

  after_create_commit { broadcast_total_points(:create) }
  after_destroy { broadcast_total_points(:destroy) }
  before_create :set_bonus_points
  after_create :set_on_streak


  def set_bonus_points
    self.bonus_points = task.calculate_bonus_points
  end

  def set_on_streak
    # Only update on_streak status if it's the default false value (not explicitly set to true)
    # This allows tests and manual creation to override the automatic calculation
    if !on_streak
      update_column(:on_streak, participant.on_streak)
    end
  end

  private
  def broadcast_total_points(action_type)
    broadcast_replace_to "participants_points",
      target: "points_for_#{self.participant.id}",
      partial: "pages/points",
      locals: {
        animate: action_type == :create,
        id: self.participant.id,
        total_points: self.participant.total_points,
        base_points: self.participant.base_points,
        bonus_points_total: self.participant.bonus_points_total
      }

    broadcast_replace_to "participants_points",
      target: "bonus_points_for_#{self.participant.id}",
      partial: "participants/bonus_points",
      locals: {
        id: self.participant.id,
        bonus_points_total: self.participant.bonus_points_total
      }
  end
end
