# config/initializers/load_users.rb

require 'yaml'
Rails.application.config.after_initialize do
  users_file = Rails.root.join('config', 'users.yml')

  if File.exist?(users_file)
    users_data = YAML.load_file(users_file)['users']
    users_data.each do |user_data|
      email = user_data['email']
      password = user_data['password']

      # Find or create the user
      user = User.find_or_initialize_by(email: email)
      user.password = password
      user.password_confirmation = password # Required if you use Devise
      user.save! if user.new_record?
    end
  end
end

