class CreateParticipants < ActiveRecord::Migration[7.0]
  def change
    create_table :participants do |t|
      t.string :name
      t.string :color
      t.string :avatar

      t.timestamps
    end
  end
end
