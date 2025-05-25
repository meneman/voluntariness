class AddDefaultValueToUserStreakBoniDaysTrashhold < ActiveRecord::Migration[8.0]
    def change
      change_column_default :users, :streak_boni_days_trashhold, 5
    end
end
