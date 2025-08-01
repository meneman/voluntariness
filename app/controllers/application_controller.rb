class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: { safari: 16.4, firefox: 121, ie: false } unless Rails.env.test? ||  Rails.env.development?
  before_action :authenticate_user!
  before_action :ensure_current_household
  after_action :track_page_view

  include Pagy::Backend

  # Global error handling
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  # Custom exception for authorization
  class Forbidden < StandardError; end
  rescue_from Forbidden, with: :forbidden



  # Firebase authentication
  def authenticate_user!
    return if user_signed_in?

    redirect_to sign_in_path, alert: "Please sign in to continue."
  end

  def current_user
    # In test environment, allow setting current user via instance variable
    return @test_current_user if Rails.env.test? && @test_current_user

    return @current_user if @current_user

    # Check session first
    if session[:user_id]
      user = User.find_by(id: session[:user_id])
      if user
        Rails.logger.debug "🔍 current_user: #{user.email} (ID: #{user.id}) from session[:user_id] = #{session[:user_id]}"
        @current_user = user
        return @current_user
      else
        Rails.logger.warn "⚠️ current_user: No user found for session[:user_id] = #{session[:user_id]}"
      end
    end

    # Check remember me cookie if no session
    if cookies.signed[:remember_token].present?
      user = User.find_by(remember_token: cookies.signed[:remember_token])
      if user&.remember_token_valid?
        Rails.logger.info "🍪 current_user: #{user.email} (ID: #{user.id}) from remember token"
        # Restore session
        session[:user_id] = user.id
        session[:firebase_uid] = user.firebase_uid
        @current_user = user
        return @current_user
      else
        Rails.logger.warn "⚠️ Invalid or expired remember token, clearing cookie"
        cookies.delete(:remember_token)
      end
    end

    @current_user = nil
  end

  def user_signed_in?
    current_user.present?
  end

  helper_method :current_user, :user_signed_in?

  private

  def not_found
    redirect_path = user_signed_in? ? pages_home_path : root_path
    redirect_to redirect_path, alert: t("flash.resource_not_found")
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

  def current_household
    @current_household ||= current_user&.current_household
  end
  helper_method :current_household

  def ensure_current_household
    return unless user_signed_in?

    unless current_household
      # If user has no current household, set the first one as current
      if current_user.households.any?
        current_user.set_current_household(current_user.households.first)
        @current_household = nil # Reset cached value
      else
        # Create a default household if user has none
        household = Household.create!(
          name: "#{current_user.email.split('@').first.humanize}'s Household",
          description: "Default household"
        )

        HouseholdMembership.create!(
          user: current_user,
          household: household,
          role: "owner",
          current_household: true
        )

        # Create default tasks for the new household
        unless DefaultTasksService.create_default_tasks_for(household)
          Rails.logger.warn "Failed to create default tasks for auto-created household #{household.id}"
        end

        @current_household = household
      end
    end
  end

  def require_household_member!
    raise Forbidden unless current_household && current_user.households.include?(current_household)
  end

  def require_household_admin!
    raise Forbidden unless current_user.can_manage_household?(current_household)
  end

  # PostHog server-side tracking
  def track_page_view
    return unless user_signed_in? && PosthogConfig.enabled?
    return if request.xhr? # Skip AJAX requests
    return unless response.successful? # Only track successful page loads

    PosthogService.track(current_user.id, "$pageview", {
      '$current_url': request.url,
      '$pathname': request.path,
      '$referrer': request.referer,
      'page_title': "Voluntariness",
      'user_agent': request.user_agent,
      'household_id': current_household&.id,
      'household_name': current_household&.name
    })
  end
end
