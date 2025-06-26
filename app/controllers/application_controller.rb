class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?
  before_action :authenticate_user!
  before_action :set_theme

  include Pagy::Backend

  # Global error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  def set_theme
    if cookies[:theme].present?
      @theme = cookies[:theme]
    else
      @theme = VoluntarinessConstants::DEFAULT_THEME
      cookies[:theme] = @theme
    end
  end

  def toggle_theme
    cookies[:theme] = params[:theme]
    @theme = cookies[:theme]
  end

  def after_sign_in_path_for(resource)
      root_path
  end

  private

  def not_found
    redirect_to root_path, alert: "Resource not found"
  end
end
