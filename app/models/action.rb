class Action < ApplicationRecord
  belongs_to :task
  belongs_to :participant

  scope :desc, ->  { order(id: :desc) }
  
  after_create_commit :broadcast_update_to_all_participants
  private

  def broadcast_update_to_all_participants
    puts self.participant.total_points
    
    


    # @participants = Participant.all()
    # @points = {}
    # @participants.each do |p|     
    broadcast_replace_to "participants_points", target: "points_for_#{self.participant.id}", partial: "pages/points", locals: { animate: true, id: self.participant.id, total_points: self.participant.total_points }
    # end
  end

end
