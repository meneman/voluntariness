class ChangeTaskWorthToDecimal < ActiveRecord::Migration[8.0]
  def change
    change_column :tasks, :worth, :decimal, precision: 10, scale: 2
  end
end
