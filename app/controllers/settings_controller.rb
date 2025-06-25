class SettingsController < ApplicationController
  before_action :authenticate_user!

  def toggle_streak_boni
    @enabled = params[:enabled] == "1"
    current_user.update(streak_boni_enabled: @enabled)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def toggle_overdue_bonus
    enabled = params[:enabled] == "1"
    current_user.update(overdue_bonus_enabled: enabled)

    respond_to do |format|
      format.turbo_stream
    end
  end

  def update_streak_bonus_days_threshold
    days_threshold = params[:days_threshold].to_i

    days_threshold = [ VoluntarinessConstants::MIN_STREAK_THRESHOLD, days_threshold ].max
    current_user.update(streak_boni_days_threshold: days_threshold)
    respond_to do |format|
      format.turbo_stream {
        flash[:notice] = "Streak bonus threshold updated to #{days_threshold} days."
        render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/action_flash")
      }
    end
  end
end
