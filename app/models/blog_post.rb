class BlogPost < ApplicationRecord
    validates :title, presence: true
    validates :body, presence: true
    scope :draft, -> {where( published_at: nil) }
    scope :published, -> {where( "published_at <= ?": Time.current) }
    scope :scheduled, -> {where( "published_at > ?": Time.current) }
end
