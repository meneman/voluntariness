class CreateTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :tasks do |t|
      t.string :title
      t.integer :worth
      t.integer :interval
      t.text :description

      t.timestamps
    end
  end
end
