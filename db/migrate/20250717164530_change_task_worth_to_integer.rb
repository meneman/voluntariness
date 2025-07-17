class ChangeTaskWorthToInteger < ActiveRecord::Migration[8.0]
  def up
    # Convert existing decimal values to integers (round to nearest integer)
    Task.find_each do |task|
      task.update_column(:worth, task.worth.to_i)
    end
    
    # Change column type from decimal to integer
    change_column :tasks, :worth, :integer
  end
  
  def down
    # Rollback: change back to decimal
    change_column :tasks, :worth, :decimal, precision: 10, scale: 2
  end
end
