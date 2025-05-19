class AddStreakBoniFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :streak_boni_enabled, :boolean
    add_column :users, :streak_boni_days_trashhold, :integer
  end
end
