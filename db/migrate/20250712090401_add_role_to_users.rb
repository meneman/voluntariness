class AddRoleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :role, :string, default: "user", null: false
    add_index :users, :role
  end
end
