class AddArchiveToP < ActiveRecord::Migration[7.0]
  def change
    add_column :participants, :archived, :boolean
  end
end
