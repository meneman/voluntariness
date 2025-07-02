class CreateUseableItems < ActiveRecord::Migration[8.0]
  def change
    create_table :useable_items do |t|
      t.string :name
      t.text :svg
      t.references :participant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
