class AddBonusPointsToActions < ActiveRecord::Migration[8.0]
  def change
    add_column :actions, :bonus_points, :integer, default: 0, null: false
  end
end
