class AddPositionToTask < ActiveRecord::Migration[7.2]
  def change
    add_column :tasks, :position, :integer
  end
end
