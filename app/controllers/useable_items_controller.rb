class UseableItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_useable_item, only: [ :show, :destroy ]
  before_action :set_participant, only: [ :index, :create ]

  def index
    @useable_items = @participant.useable_items
    @obtainable_items = UseableItem.obtainable_items
  end

  def show
  end

  def create
    @useable_item = UseableItem.create_from_obtainable(@participant, params[:item_name])

    if @useable_item&.persisted?
      redirect_to useable_items_path(participant_id: @participant.id), notice: "Item obtained successfully!"
    else
      redirect_to useable_items_path(participant_id: @participant.id), alert: "Could not obtain item."
    end
  end

  def destroy
    @useable_item.destroy
    redirect_to useable_items_path(participant_id: @useable_item.participant.id), notice: "Item removed successfully!"
  end

  private

  def set_useable_item
    @useable_item = current_user.participants.joins(:useable_items).find_by(useable_items: { id: params[:id] })&.useable_items&.find(params[:id])
    redirect_to root_path, alert: "Item not found." unless @useable_item
  end

  def set_participant
    @participant = current_user.participants.find(params[:participant_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Participant not found."
  end
end
