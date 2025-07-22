class HouseholdMembership < ApplicationRecord
  belongs_to :user
  belongs_to :household

  validates :role, presence: true, inclusion: { in: %w[owner admin member] }
  validates :user_id, uniqueness: { scope: :household_id }

  scope :current, -> { where(current_household: true) }
  scope :owners, -> { where(role: "owner") }
  scope :admins, -> { where(role: "admin") }
  scope :members, -> { where(role: "member") }

  def owner?
    role == "owner"
  end

  def admin?
    role == "admin"
  end

  def member?
    role == "member"
  end

  def can_manage_household?
    owner? || admin?
  end
end
