class RemoveDeviseFromUsers < ActiveRecord::Migration[8.0]
  def change
    # Remove Devise fields
    remove_column :users, :encrypted_password, :string if column_exists?(:users, :encrypted_password)
    remove_column :users, :reset_password_token, :string if column_exists?(:users, :reset_password_token)
    remove_column :users, :reset_password_sent_at, :datetime if column_exists?(:users, :reset_password_sent_at)
    remove_column :users, :remember_created_at, :datetime if column_exists?(:users, :remember_created_at)
    
    # Remove Devise indexes
    remove_index :users, :reset_password_token if index_exists?(:users, :reset_password_token)
    
    # Add Firebase authentication field
    add_column :users, :firebase_uid, :string, null: false, default: '' unless column_exists?(:users, :firebase_uid)
    add_index :users, :firebase_uid, unique: true unless index_exists?(:users, :firebase_uid)
  end
end
