class CreateHouseholdMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :household_memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :household, null: false, foreign_key: true
      t.string :role, default: 'member'
      t.boolean :current_household, default: false

      t.timestamps
    end

    add_index :household_memberships, [:user_id, :household_id], unique: true
    add_index :household_memberships, [:user_id, :current_household]
  end
end
