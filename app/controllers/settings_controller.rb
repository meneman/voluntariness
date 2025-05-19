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

  def update_streak_bonus_days_trashhold
    days_trashhold = params[:days_trashhold].to_i

    # Ensure the threshold is at least 1 day
    days_trashhold = [ 1, days_trashhold ].max

    # Update the threshold in your settings model/table
    # This will depend on how you're storing settings, but could be something like:
    current_user.update(streak_boni_days_trashhold: days_trashhold)

    # Redirect back to settings page
    respond_to do |format|
      format.turbo_stream {
        flash[:notice] = "Streak bonus threshold updated to #{days_trashhold} days."
        render turbo_stream: turbo_stream.prepend("flash", partial: "layouts/action_flash")
      }
    end
  end
end
