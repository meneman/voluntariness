class Action < ApplicationRecord
  belongs_to :task
  belongs_to :participant

  scope :last_five_days, -> { where(created_at: 10.days.ago.beginning_of_day..Time.now.end_of_day) }
  scope :desc, ->  { order(id: :desc) }

  after_create_commit { broadcast_total_points(:create) }
  after_destroy { broadcast_total_points(:destroy) }
  before_create :set_bonus_points


  def set_bonus_points
    self.bonus_points = task.calculate_bonus_points
  end

  private
  def broadcast_total_points(action_type)
    broadcast_replace_to "participants_points",
     target: "points_for_#{self.participant.id}",
      partial: "pages/points",
       locals: { animate: action_type == :create, id: self.participant.id, total_points: self.participant.total_points }
  end
end
