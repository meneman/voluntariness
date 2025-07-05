class BetsController < ApplicationController
  before_action :set_bet, except: [ :index, :new, :create ]

  def index
    @pagy, @bets = pagy(current_user.bets, {})
  end

  def show
  end

  def new
    @bet = Bet.new
    @participants = current_user.participants.active
    respond_to do |format|
      format.html
    end
  end

  def edit
  end

  def create
    return redirect_to root_path, alert: t("flash.missing_required_data") unless params[:data]

    participant = current_user.participants.find(params[:data][:participant_id])

    @bet = Bet.new(
      participant_id: participant.id,
      cost: params[:data][:cost],
      description: params[:data][:description],
      outcome: params[:data][:outcome] || "pending"
    )

    if @bet.save
      respond_to do |format|
        format.html { redirect_to bets_path, notice: t("flash.bet_created") }
        format.turbo_stream { flash.now[:bet_flash] = @bet }
      end
    else
      @participants = current_user.participants.active
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @bet.update(bet_params)
      redirect_to @bet, notice: t("flash.bet_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @bet.destroy
    respond_to do |format|
      format.html { redirect_to bets_path, notice: t("flash.bet_deleted") }
      format.turbo_stream
    end
  end

  private

  def bet_params
    if params[:bet].present? && params[:bet].respond_to?(:permit)
      params.require(:bet).permit(:participant_id, :cost, :description, :outcome)
    else
      {}
    end
  end

  def set_bet
    @bet = current_user.bets.find(params[:id])
  end
end
