class AddThemePreferenceToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :theme_preference, :string, default: 'system'
  end
end
