class MigrateUserDataToHouseholds < ActiveRecord::Migration[8.0]
  def up
    # Create a household for each existing user
    User.find_each do |user|
      # Create household for user
      household = Household.create!(
        name: "#{user.email.split('@').first.humanize}'s Household",
        description: "Default household for #{user.email}"
      )

      # Create membership for user as owner
      HouseholdMembership.create!(
        user: user,
        household: household,
        role: 'owner',
        current_household: true
      )

      # Migrate tasks to household
      Task.where(user_id: user.id).update_all(household_id: household.id)

      # Migrate participants to household  
      Participant.where(user_id: user.id).update_all(household_id: household.id)
    end
  end

  def down
    # Remove household associations and delete households
    HouseholdMembership.delete_all
    Task.update_all(household_id: nil)
    Participant.update_all(household_id: nil)
    Household.delete_all
  end
end
