class Participant < ApplicationRecord
    belongs_to :user
    has_many :actions, dependent: :destroy, after_remove: :log_action_removal
    has_many :tasks, through: :actions, dependent: :nullify
    validates :name, presence: true
    scope :active, -> { where("archived = false") }

    def log_action_removal(action)
        puts self
          Rails.logger.info "Participant changed #{id}."
    end

    def total_points
        # Use database aggregation instead of Ruby iteration to avoid N+1 queries
        base_points = actions.joins(:task).sum("tasks.worth")
        bonus_points = actions.sum("COALESCE(bonus_points, 0)")
        streak_bonus = user.streak_boni_enabled? ? actions.where(on_streak: true).count : 0

        total = base_points + bonus_points + streak_bonus
        # rounds only if decimals are not 0s
        "%g" % ("%.1f" % total)
    end



    def streak
        return -1 unless self.user.streak_boni_enabled?
        days_with_action = actions.last_five_days.reverse.map { |action| action.created_at.to_date }.uniq
        current_day = Time.now.to_date
        streak_count = 0
        days_with_action.each { |day|
            if day == current_day
                streak_count += 1
                current_day = current_day - 1.day
            else
                break
            end
        }
        streak_count
    end


    def on_streak
        streak > self.user.streak_boni_days_threshold # returns true if the streak count is more than the set threshold
    end

    private

    def apply_bonuses(base_points, action)
      [
        ->(pts) { user.streak_boni_enabled? && action.on_streak? ? pts + VoluntarinessConstants::STREAK_BONUS_POINTS : pts },
        ->(pts) { user.overdue_bonus_enabled? ? pts + action.bonus_points : pts }
      ].reduce(base_points) { |points, bonus_fn| bonus_fn.call(points) }
    end
end
