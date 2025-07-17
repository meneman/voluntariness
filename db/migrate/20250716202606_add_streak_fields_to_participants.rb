class AddStreakFieldsToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_column :participants, :streak, :integer unless column_exists?(:participants, :streak)
    add_column :participants, :on_streak, :boolean unless column_exists?(:participants, :on_streak)
    
    add_index :participants, :on_streak unless index_exists?(:participants, :on_streak)
  end
end
