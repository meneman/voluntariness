# lib/tasks/create_user.rake

namespace :user do
  desc "Create a user with a random password"
  task create: :environment do
    # Prompt for email input
    puts "Enter the email for the new user:"
    email = STDIN.gets.strip

    # Check if the email is provided
    if email.empty?
      puts "No email provided. Task aborted."
      exite
    end

    # Generate a random password using SecureRandom
    password = SecureRandom.hex(3) # Generates a random 16-character string

    # Create or find the user
    user = User.find_or_initialize_by(email: email)

    if user.persisted?
      puts "User with this email already exists."
    else
      user.password = password
      user.password_confirmation = password # If you use Devise or password confirmation
      if user.save
        puts "User created successfully!"
        puts "Email: #{email}"
        puts "Password: #{password}"
      else
        puts "User could not be created. Errors: #{user.errors.full_messages.join(", ")}"
      end
    end
  end
end
