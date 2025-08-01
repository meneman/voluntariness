class Task < ApplicationRecord
    belongs_to :household
    has_many :actions, dependent: :destroy
    validates :title, presence: true
    validates :worth, presence: true, numericality: { only_integer: true }
    acts_as_list

    scope :active, -> { where("archived = false") }
    scope :ordered, -> { order(position: :asc) }

    after_update_commit :update_participant_points_if_worth_changed

    def done_today
        return false unless actions.last
        actions.last.created_at.to_date == Date.today
    end


    def overdue
        if self.interval.nil?
            return nil
        end
        if actions.last
         overdue_on = actions.last.created_at.to_date + self.interval
        else
         overdue_on = self.created_at&.to_date || Time.current.to_date
        end
        today = Time.now
        (overdue_on.to_date - today.to_date).to_i
    end

    def calculate_bonus_points
        return 0 unless household.users.first&.overdue_bonus_enabled?
        return 0 if overdue.nil?
        return 0 if overdue >= 0

        # Bonus-Formel: 1 Punkt pro überfälligen Tag, maximal 50% der Basis-Punkte
        (overdue.abs * VoluntarinessConstants::OVERDUE_BONUS_MULTIPLIER).round(1)
    end

    private

    def update_participant_points_if_worth_changed
        return unless saved_change_to_worth?

        # Update all action_participants for this task with the new points value
        ActionParticipant.joins(:action)
                        .where(actions: { task_id: id })
                        .update_all(points_earned: worth)

        # Broadcast updated points for all affected participants
        affected_participants = Participant.joins(action_participants: :action)
                                          .where(actions: { task_id: id })
                                          .distinct

        affected_participants.find_each do |participant|
            participant.reload # Ensure fresh data
            broadcast_replace_to "participants_points",
                target: "points_for_#{participant.id}",
                partial: "pages/points",
                locals: {
                    animate: true,
                    id: participant.id,
                    total_points: participant.total_points,
                    base_points: participant.base_points,
                    bonus_points_total: participant.bonus_points_total
                }

            broadcast_replace_to "participants_points",
                target: "bonus_points_for_#{participant.id}",
                partial: "participants/bonus_points",
                locals: {
                    id: participant.id,
                    bonus_points_total: participant.bonus_points_total
                }
        end
    end
end
