class Action < ApplicationRecord
  belongs_to :task
  belongs_to :participant

  scope :desc, ->  { order(id: :desc) }
  
  after_create_commit { broadcast_total_points(:create)}

  after_destroy { broadcast_total_points(:destroy)}

  private
  def broadcast_total_points(action_type)
    puts action_type
    broadcast_replace_to "participants_points",
     target: "points_for_#{self.participant.id}",
      partial: "pages/points",
       locals: { animate: action_type == :create , id: self.participant.id, total_points: self.participant.total_points }
  end
   
end
