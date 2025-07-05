class CreateBets < ActiveRecord::Migration[8.0]
  def change
    create_table :bets do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :outcome
      t.decimal :cost, precision: 8, scale: 2
      t.text :description

      t.timestamps
    end
  end
end
