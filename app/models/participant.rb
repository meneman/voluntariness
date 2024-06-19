class Participant < ApplicationRecord
    has_many :actions
    has_many :tasks, through: :actions
    validates :name, presence: true
    
    def total_points
        actions.sum {|a| a.task[:worth] }
    end
end
