class MigrateActionsToSharedStructure < ActiveRecord::Migration[8.0]
  def up
    # Migrate existing actions to the new structure
    execute <<-SQL
      INSERT INTO action_participants (action_id, participant_id, points_earned, bonus_points, on_streak, created_at, updated_at)
      SELECT 
        a.id,
        a.participant_id,
        t.worth,
        COALESCE(a.bonus_points, 0),
        COALESCE(a.on_streak, false),
        a.created_at,
        a.updated_at
      FROM actions a
      JOIN tasks t ON t.id = a.task_id
      WHERE a.participant_id IS NOT NULL
    SQL
    
    # Remove the old participant_id column and related fields from actions
    remove_column :actions, :participant_id
    remove_column :actions, :bonus_points if column_exists?(:actions, :bonus_points)
    remove_column :actions, :on_streak if column_exists?(:actions, :on_streak)
  end
  
  def down
    # Add back the old columns
    add_reference :actions, :participant, null: true, foreign_key: true
    add_column :actions, :bonus_points, :decimal, precision: 8, scale: 2
    add_column :actions, :on_streak, :boolean, default: false
    
    # Migrate data back (only works if each action has exactly one participant)
    execute <<-SQL
      UPDATE actions 
      SET participant_id = (
        SELECT participant_id 
        FROM action_participants 
        WHERE action_participants.action_id = actions.id 
        LIMIT 1
      ),
      bonus_points = (
        SELECT bonus_points 
        FROM action_participants 
        WHERE action_participants.action_id = actions.id 
        LIMIT 1
      ),
      on_streak = (
        SELECT on_streak 
        FROM action_participants 
        WHERE action_participants.action_id = actions.id 
        LIMIT 1
      )
    SQL
    
    # Drop the join table
    drop_table :action_participants
  end
end
