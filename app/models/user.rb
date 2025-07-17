class User < ApplicationRecord
  has_many :tasks, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :actions, through: :tasks
  has_many :bets, through: :participants

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :database_authenticatable,
  :recoverable, :rememberable, :validatable, :registerable


  def remember_me
    true
  end

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
end
