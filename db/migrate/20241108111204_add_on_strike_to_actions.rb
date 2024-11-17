class AddOnStrikeToActions < ActiveRecord::Migration[7.2]
  def change
    add_column :actions, :on_strike, :boolean, default: false, null: false
  end
end
