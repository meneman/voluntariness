class AddHouseholdToParticipants < ActiveRecord::Migration[8.0]
  def change
    add_reference :participants, :household, null: true, foreign_key: true
    add_index :participants, :household_id unless index_exists?(:participants, :household_id)
  end
end
