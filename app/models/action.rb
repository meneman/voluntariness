class Action < ApplicationRecord
  belongs_to :task
  has_many :action_participants, dependent: :destroy
  has_many :participants, through: :action_participants

  scope :last_five_days, -> { where(created_at: VoluntarinessConstants::STREAK_CALCULATION_DAYS.days.ago.beginning_of_day..Time.now.end_of_day) }
  scope :desc, ->  { order(id: :desc) }

  after_create :set_participant_data

  # Add participants to this action
  def add_participants(participant_ids, bonus_points: nil)
    # Calculate bonus points before adding participants if not provided
    bonus_points = task.calculate_bonus_points if bonus_points.nil?
    
    participant_ids.each do |participant_id|
      participant = Participant.find(participant_id)
      points = task.worth
      
      # Validate negative points are only allowed for gambling/penalty tasks
      if points < 0 && !gambling_or_penalty_task?
        raise ArgumentError, "Negative points are only allowed for gambling or penalty tasks"
      end
      
      streak = participant.on_streak

      action_participants.create!(
        participant: participant,
        points_earned: points,
        bonus_points: bonus_points,
        on_streak: streak
      )
    end
  end

  # For backward compatibility - return primary participant
  def participant
    participants.first
  end

  # For backward compatibility - return primary participant's bonus points
  def bonus_points
    action_participants.first&.bonus_points || 0
  end

  # For backward compatibility - return primary participant's streak status
  def on_streak
    action_participants.first&.on_streak || false
  end
  
  private
  
  def gambling_or_penalty_task?
    # Check if this is a gambling task (you may need to adjust this logic based on your task categorization)
    task.title.downcase.include?('gamble') || 
    task.title.downcase.include?('bet') || 
    task.description&.downcase&.include?('gambling') ||
    task.worth < 0 # Temporary: assume negative worth tasks are gambling/penalties
  end

  private

  def set_participant_data
    # This will be called after creation, but actual participant data
    # should be set via add_participants method
  end
end
