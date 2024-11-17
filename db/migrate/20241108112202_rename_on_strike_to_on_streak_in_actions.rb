class RenameOnStrikeToOnStreakInActions < ActiveRecord::Migration[7.2]
  def change
    rename_column :actions, :on_strike, :on_streak
  end
end
