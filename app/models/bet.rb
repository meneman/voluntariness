class Bet < ApplicationRecord
  belongs_to :participant

  validates :cost, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true
  validates :outcome, inclusion: { in: %w[pending won lost], message: "%{value} is not a valid outcome" }

  scope :pending, -> { where(outcome: "pending") }
  scope :won, -> { where(outcome: "won") }
  scope :lost, -> { where(outcome: "lost") }
  scope :desc, -> { order(id: :desc) }

  after_create_commit { broadcast_bet_update(:create) }
  after_update_commit { broadcast_bet_update(:update) }
  after_destroy { broadcast_bet_update(:destroy) }

  private

  def broadcast_bet_update(action_type)
    broadcast_replace_to "participant_bets",
      target: "bets_for_#{self.participant.id}",
      partial: "bets/bet_summary",
      locals: {
        participant: self.participant,
        action_type: action_type
      }
  end
end
