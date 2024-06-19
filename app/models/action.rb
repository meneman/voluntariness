class Action < ApplicationRecord
  belongs_to :task
  belongs_to :participant


  after_create_commit :broadcast_update_to_all_participants
  private

  def broadcast_update_to_all_participants
    @participants = Participant.all()
    @points = {}
    @participants.each do |p|
       
      broadcast_replace_to "participants_points", target: "points_for_#{p.id}", partial: "pages/points", locals: { id: p.id, total_points: p.total_points }
    end
  end

end
