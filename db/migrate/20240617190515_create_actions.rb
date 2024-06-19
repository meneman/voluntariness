class CreateActions < ActiveRecord::Migration[7.0]
  def change
    create_table :actions do |t|
      t.references :task, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true
      t.datetime :timestamp

      t.timestamps
    end
  end
end
