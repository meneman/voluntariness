require 'ostruct'

class StyleGuideController < ApplicationController
  before_action :authenticate_user!

  def index
    # Sample data for style guide demonstrations
    @participants = current_user.participants.active.limit(3)
    
    @sample_participant = @participants.first || OpenStruct.new(
      name: "Alice Sample",
      color: "#FF6B6B",
      total_points: 42.5,
      bonus_points_total: 12.0
    )
    
    @sample_task = current_user.tasks.first || OpenStruct.new(
      title: "Sample Task",
      description: "This is a sample task description for the style guide",
      worth: 10.0
    )
    
    @sample_bet = OpenStruct.new(
      cost: 5.0,
      description: "Sample betting activity",
      outcome: "pending"
    )
  end
end