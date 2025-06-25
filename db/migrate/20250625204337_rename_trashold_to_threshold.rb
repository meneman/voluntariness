class RenameTrasholdToThreshold < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :streak_boni_days_trashhold, :streak_boni_days_threshold
  end
end
