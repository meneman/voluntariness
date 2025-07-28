class AddRememberTokenToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :remember_token, :string
    add_column :users, :remember_created_at, :datetime
    add_index :users, :remember_token
  end
end
