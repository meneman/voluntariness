class Household < ApplicationRecord
  has_many :household_memberships, dependent: :destroy
  has_many :users, through: :household_memberships
  has_many :tasks, dependent: :destroy
  has_many :participants, dependent: :destroy
  has_many :actions, through: :tasks

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  before_create :generate_invite_code

  def can_add_task?
    tasks.active.count < 30
  end

  def participants_data_for_chatgpt
    ChatGptPromptService.new(self).generate_prompt
  end

  private

  def generate_invite_code
    self.invite_code = SecureRandom.hex(6).upcase until invite_code_unique?
  end

  def invite_code_unique?
    invite_code && !Household.exists?(invite_code: invite_code)
  end
end