class CreateActionParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :action_participants do |t|
      t.references :action, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.decimal :points_earned, precision: 8, scale: 2
      t.decimal :bonus_points, precision: 8, scale: 2, default: 0
      t.boolean :on_streak, default: false

      t.timestamps
    end
    
    add_index :action_participants, [:action_id, :participant_id], unique: true
  end
end
