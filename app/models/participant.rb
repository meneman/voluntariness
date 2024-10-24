class Participant < ApplicationRecord
    belongs_to :user
    has_many :actions,  dependent: :destroy, after_remove: :log_action_removal
    has_many :tasks, through: :actions
    validates :name, presence: true
    scope :active, -> { where( "archived = false") }

    def log_action_removal(action)
        puts self
          Rails.logger.info "Participant changed #{id}."
    end
    
    def total_points
        actions.sum {|a| a.task[:worth] }
    end

    
    def streak
        days_with_action = actions.last_five_days.reverse.map {|action| action.created_at.to_date}.uniq
        current_day = Time.now.to_date
        streak_count = 0 
        days_with_action.each { |day| 
            if day == current_day 
                streak_count++
                current_day = current_day - 1.day
            else 
                break 
            end
        }
        streak_count
    end
end
