class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?
  before_action :authenticate_user!
  before_action :set_theme

  include Pagy::Backend

  # Global error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # Custom exception for authorization
  class Forbidden < StandardError; end
  rescue_from Forbidden, with: :forbidden


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
    redirect_to root_path, alert: t("flash.resource_not_found")
  end

  def forbidden
    redirect_to root_path, alert: "You don't have permission to access this page."
  end

  def require_admin!
    raise Forbidden unless current_user&.admin?
  end

  def require_admin_or_support!
    raise Forbidden unless current_user&.admin? || current_user&.support?
  end
end
