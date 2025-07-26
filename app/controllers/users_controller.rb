class UsersController < ApplicationController
  before_action :authenticate_user!
  
  def update_theme
    theme = params[:theme]
    
    if %w[light dark system].include?(theme)
      current_user.update!(theme_preference: theme)
      render json: { status: 'success', theme: theme }
    else
      render json: { status: 'error', message: 'Invalid theme' }, status: 400
    end
  end
end