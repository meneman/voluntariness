class AddOverdueBonusEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :overdue_bonus_enabled, :boolean
  end
end
