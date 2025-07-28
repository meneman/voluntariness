class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def update_theme
    theme = params[:theme]
    previous_theme = current_user.theme_preference
    
    if %w[light dark system].include?(theme)
      current_user.update!(theme_preference: theme)
      
      # Track theme change server-side
      PosthogService.track(current_user.id, 'theme_changed', {
        new_theme: theme,
        previous_theme: previous_theme,
        source: 'server_api'
      })
      
      render json: { status: 'success', theme: theme }
    else
      render json: { status: 'error', message: 'Invalid theme' }, status: 400
    end
  end
end