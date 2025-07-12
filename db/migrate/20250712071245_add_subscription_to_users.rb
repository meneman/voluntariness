class AddSubscriptionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :subscription_plan, :string, default: 'free'
    add_column :users, :subscription_status, :string, default: 'active'
    add_column :users, :subscription_purchased_at, :datetime
    add_column :users, :lifetime_access, :boolean, default: false
    
    add_index :users, :subscription_plan
    add_index :users, :subscription_status
  end
end
