namespace :admin do
  desc "Promote a user to admin role"
  task :promote, [:email] => :environment do |task, args|
    email = args[:email]
    if email.blank?
      puts "Usage: rails admin:promote[email@example.com]"
      exit 1
    end

    user = User.find_by(email: email)
    if user
      user.update!(role: "admin")
      puts "✅ #{email} has been promoted to admin"
    else
      puts "❌ User with email #{email} not found"
    end
  end

  desc "List all admin users"
  task :list => :environment do
    admins = User.where(role: "admin")
    if admins.any?
      puts "Admin users:"
      admins.each { |user| puts "- #{user.email}" }
    else
      puts "No admin users found"
    end
  end
end