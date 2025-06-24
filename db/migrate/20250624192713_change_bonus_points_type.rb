class ChangeBonusPointsType < ActiveRecord::Migration[8.0]
  def change
    change_column(:actions, :bonus_points, :float)
  end
end
