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
end
