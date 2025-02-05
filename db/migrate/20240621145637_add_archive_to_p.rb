class AddArchiveToP < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :archived, :boolean, :default => false
  end
end
