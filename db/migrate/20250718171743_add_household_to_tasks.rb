class AddHouseholdToTasks < ActiveRecord::Migration[8.0]
  def change
    add_reference :tasks, :household, null: true, foreign_key: true
    add_index :tasks, :household_id unless index_exists?(:tasks, :household_id)
  end
end
