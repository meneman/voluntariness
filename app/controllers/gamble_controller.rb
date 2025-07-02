class GambleController < ApplicationController
  before_action :authenticate_user!
  before_action :set_participant, only: [ :spin, :result ]

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :parameter_missing

  def index
    @participants = current_user.participants.active
    @selected_participant = nil
    @step = "select"
  end

  def select_participant
    @participant = current_user.participants.active.find(params.require(:participant_id))

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("gamble_content",
          partial: "gamble/bet_section",
          locals: { participant: @participant }
        ) + turbo_stream.update("gamble_step_indicator",
          partial: "gamble/step_indicator",
          locals: { current_step: "bet" }
        )
      end
    end
  end

  def spin
    if @participant.total_points.to_f < 1
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("gamble_content",
            partial: "gamble/insufficient_points",
            locals: { participant: @participant }
          )
        end
      end
      return
    end

    # Create or find a gambling task for deducting points
    gamble_task = Task.find_or_create_by(
      user: current_user,
      title: "Gamble Bet",
      worth: -1
    ) do |task|
      task.description = "Point deducted for gambling"
      task.archived = false
    end

    # Deduct 1 point by creating a negative action
    Action.create!(
      participant: @participant,
      task: gamble_task,
      bonus_points: 0
    )

    # Store the winning item in session for the result page
    @winning_item = VoluntarinessConstants::OBTAINABLE_ITEMS.sample
    session[:winning_item] = @winning_item

    # Calculate the target angle for the predetermined winner
    items = VoluntarinessConstants::OBTAINABLE_ITEMS
    winning_index = items.index(@winning_item)
    degrees_per_section = 360.0 / items.length
    target_angle = winning_index * degrees_per_section + (degrees_per_section / 2)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("gamble_content",
          partial: "gamble/spinning_section",
          locals: { participant: @participant, target_angle: target_angle, winning_item: @winning_item }
        ) + turbo_stream.update("gamble_step_indicator",
          partial: "gamble/step_indicator",
          locals: { current_step: "spin" }
        )
      end
      format.html do
        redirect_to gamble_path
      end
    end
  end

  def result
    # Get the winning item from session (set during spin)
    @winning_item = session[:winning_item]

    # Fallback: if no item in session, select a random one
    unless @winning_item
      @winning_item = VoluntarinessConstants::OBTAINABLE_ITEMS.sample
    end

    # Ensure we have a valid winning item
    @winning_item ||= VoluntarinessConstants::OBTAINABLE_ITEMS.first

    # Convert string keys to symbols if needed (session might store as strings)
    if @winning_item && @winning_item.is_a?(Hash)
      @winning_item = @winning_item.symbolize_keys if @winning_item.respond_to?(:symbolize_keys)
    end

    # Create the useable item for the participant
    if @winning_item && @participant && @winning_item[:name].present?
      UseableItem.create_from_obtainable(@participant, @winning_item[:name])
    end

    # Clear the session
    session.delete(:winning_item)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("gamble_content",
          partial: "gamble/result_section",
          locals: { participant: @participant, winning_item: @winning_item }
        ) + turbo_stream.update("gamble_step_indicator",
          partial: "gamble/step_indicator",
          locals: { current_step: "result" }
        )
      end
      format.html do
        # Fallback for non-Turbo requests
        redirect_to gamble_path
      end
    end
  end

  def reset
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("gamble_content",
          partial: "gamble/participant_selection",
          locals: { participants: current_user.participants.active }
        ) + turbo_stream.update("gamble_step_indicator",
          partial: "gamble/step_indicator",
          locals: { current_step: "select" }
        )
      end
      format.html do
        redirect_to gamble_path
      end
    end
  end

  private

  def set_participant
    @participant = current_user.participants.active.find(params.require(:participant_id))
  end

  def record_not_found
    respond_to do |format|
      format.turbo_stream { head :not_found }
      format.html { head :not_found }
    end
  end

  def parameter_missing
    respond_to do |format|
      format.turbo_stream { head :bad_request }
      format.html { head :bad_request }
    end
  end
end
