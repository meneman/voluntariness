class RemoveUserIdFromTasksAndParticipants < ActiveRecord::Migration[8.0]
  def change
    remove_reference :tasks, :user, foreign_key: true
    remove_reference :participants, :user, foreign_key: true
  end
end
