class User < ApplicationRecord
  has_many :tasks, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :actions, through: :participants

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable

  devise :database_authenticatable,
  :recoverable, :rememberable, :validatable, :registerable


  def remember_me
    true
  end
end
