class Task < ApplicationRecord
    belongs_to :user
    has_many :actions
    validates :title, presence: true
    validates :worth, presence: true
    acts_as_list

    scope :active, -> { where("archived = false") }
    scope :ordered, -> { order(position: :asc) }


    def done_today
        if actions.last
            actions.last.created_at.to_date == Date.today
        end
    end


    def overdue
        if self.interval.nil?
            return nil
        end
        if actions.last
         overdue_on = actions.last.created_at.to_date + self.interval
        else
         overdue_on = self.created_at
        end
        today = Time.now
        (overdue_on.to_date - today.to_date).to_i
    end
end
