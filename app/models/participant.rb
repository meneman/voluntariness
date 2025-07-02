class Participant < ApplicationRecord
    belongs_to :user
    has_many :actions, dependent: :destroy
    has_many :tasks, through: :actions, dependent: :nullify
    has_many :useable_items, dependent: :destroy
    validates :name, presence: true
    scope :active, -> { where("archived = false") }



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

        days_with_action = actions.last_five_days.map { |action| action.created_at.to_date }.uniq.sort.reverse
        return 0 if days_with_action.empty?

        # A streak should count consecutive days leading up to today (or yesterday at most)
        # If the most recent action is more than 1 day old, there's no current streak
        most_recent_action_date = days_with_action.first
        today = Time.current.to_date

        # If the most recent action is more than 1 day old, no current streak
        return 0 if most_recent_action_date < today - 1.day

        # Start counting from today or the most recent action date
        current_day = [ today, most_recent_action_date ].min
        streak_count = 0

        days_with_action.each do |day|
            if day == current_day
                streak_count += 1
                current_day = current_day - 1.day
            else
                break
            end
        end

        streak_count
    end


    def on_streak
        streak > self.user.streak_boni_days_threshold # returns true if the streak count is more than the set threshold
    end

    def log_action_removal(action)
        # Log the removal of an action for audit purposes
        Rails.logger.info "Action #{action.id} removed from participant #{self.name} (#{self.id})"
    end

    private

    def apply_bonuses(base_points, action)
      [
        ->(pts) { user.streak_boni_enabled? && action.on_streak? ? pts + VoluntarinessConstants::STREAK_BONUS_POINTS : pts },
        ->(pts) { user.overdue_bonus_enabled? ? pts + action.bonus_points : pts }
      ].reduce(base_points) { |points, bonus_fn| bonus_fn.call(points) }
    end
end
