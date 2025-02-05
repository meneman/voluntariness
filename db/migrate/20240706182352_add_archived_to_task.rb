class AddArchivedToTask < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :archived, :boolean, :default => false
  end
end
  