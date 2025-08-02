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
    participants_data = participants.active.includes(
      action_participants: { action: :task }
    ).map.with_index(1) do |participant, index|
      # Get all completed actions for this participant
      completed_action_participants = participant.action_participants.includes(action: :task)

      # Calculate basic metrics
      total_points_float = participant.total_points.to_f
      completed_tasks_count = completed_action_participants.count
      average_points_per_task = completed_tasks_count > 0 ? (total_points_float / completed_tasks_count).round(2) : 0

      # Current streak
      current_streak = participant.streak.to_i

      # Overdue tasks count - tasks assigned to this participant that are overdue
      overdue_tasks_count = tasks.active.select { |task|
        overdue_value = task.overdue
        overdue_value.is_a?(Integer) && overdue_value < 0
      }.count

      # Tasks due soon count - tasks that will be overdue within 24 hours
      tasks_due_soon_count = tasks.active.select { |task|
        overdue_value = task.overdue
        overdue_value.is_a?(Integer) && overdue_value >= 0 && overdue_value <= 1
      }.count

      # Task completion breakdown - count of completions per task title
      task_completion_breakdown = completed_action_participants
        .group_by { |ap| ap.action.task.title }
        .transform_values(&:count)

      {
        participant_id: participant.id,
        name: "Participant #{('A'.ord + index - 1).chr}",
        total_points: total_points_float,
        completed_tasks_count: completed_tasks_count,
        average_points_per_task: average_points_per_task,
        current_streak: current_streak,
        overdue_tasks_assigned_count: overdue_tasks_count,
        tasks_due_soon_count: tasks_due_soon_count,
        task_completion_breakdown: task_completion_breakdown
      }
    end

    # Convert to JSON and create ChatGPT prompt
    json_data = participants_data.to_json

    prompt = "Hello ChatGPT, please analyze the following household participant data, including task-specific completion counts:\n\n" +
             json_data +
             "\n\nBased on this data, please provide insights, identify patterns (especially regarding task specialization), offer constructive feedback, and suggest ways to improve task distribution or motivation within the household. Focus on actionable advice."

    prompt
  end

  private

  def generate_invite_code
    self.invite_code = SecureRandom.hex(6).upcase until invite_code_unique?
  end

  def invite_code_unique?
    invite_code && !Household.exists?(invite_code: invite_code)
  end
end