class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :authenticate_user!
  before_action :set_theme

  include Pagy::Backend

  def set_theme
    if cookies[:theme].present?
      @theme = cookies[:theme]
    else
      @theme = 'dark' # Default to LIGHT theme
      cookies[:theme] = @theme
    end
  end   

  def toggle_theme
    
    cookies[:theme] = params[:theme]
  end

  def after_sign_in_path_for(resource)
      root_path
  end
end
