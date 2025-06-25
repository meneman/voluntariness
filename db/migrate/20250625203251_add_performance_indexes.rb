class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Add composite indexes for common query patterns
    add_index :actions, [:created_at, :participant_id], name: 'index_actions_on_created_at_and_participant_id'
    add_index :actions, [:created_at, :task_id], name: 'index_actions_on_created_at_and_task_id'
    add_index :actions, [:participant_id, :created_at], name: 'index_actions_on_participant_id_and_created_at'
    
    # Add index for tasks position (used by acts_as_list)
    add_index :tasks, :position
    
    # Add index for tasks archived status for active scope
    add_index :tasks, :archived
    
    # Add index for participants archived status for active scope
    add_index :participants, :archived
  end
end
