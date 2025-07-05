class UseableItem < ApplicationRecord
  belongs_to :participant

  validates :name, presence: true
  validates :svg, presence: true

  def self.obtainable_items
    VoluntarinessConstants::OBTAINABLE_ITEMS
  end

  def self.create_from_obtainable(participant, item_name)
    item_data = obtainable_items.find { |item| item[:name] == item_name }
    return nil unless item_data

    create(
      participant: participant,
      name: item_data[:name],
      svg: item_data[:svg]
    )
  end
end
