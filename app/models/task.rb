class Task < ApplicationRecord

    validates :title, presence: true
    validates :worth, presence: true

end
