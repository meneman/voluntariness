class User < ApplicationRecord
  has_many :household_memberships, dependent: :destroy
  has_many :households, through: :household_memberships
  has_many :tasks, through: :households
  has_many :participants, through: :households
  has_many :actions, through: :tasks
  has_many :bets, through: :participants

  # Firebase authentication - no Devise modules needed
  validates :email, presence: true, uniqueness: true
  validates :firebase_uid, presence: true, uniqueness: true

  after_create :create_default_household

  def premium_plan?
    subscription_plan != "free" && subscription_status == "active"
  end

  def plan_display_name
    case subscription_plan
    when "premium"
      "Premium"
    when "pro"
      "Pro"
    when "enterprise"
      "Enterprise"
    else
      "Free"
    end
  end

  def admin?
    role == "admin"
  end

  def user?
    role == "user"
  end

  def support?
    role == "support"
  end

  def role_display_name
    role.humanize
  end

  def current_household
    household_memberships.find_by(current_household: true)&.household
  end

  def set_current_household(household)
    transaction do
      household_memberships.update_all(current_household: false)
      household_memberships.find_by(household: household)&.update(current_household: true)
    end
  end

  def household_role_in(household)
    household_memberships.find_by(household: household)&.role
  end

  def can_manage_household?(household)
    membership = household_memberships.find_by(household: household)
    membership&.can_manage_household?
  end

  def can_create_household?
    households.count < 5
  end

  def can_join_household?
    households.count < 5
  end

  private

  def create_default_household
    household = Household.create!(
      name: "#{email.split('@').first.humanize}'s Household",
      description: "Default household for #{email}"
    )

    HouseholdMembership.create!(
      user: self,
      household: household,
      role: 'owner',
      current_household: true
    )
  end
end
