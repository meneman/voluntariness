class AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:sign_in, :sign_up, :verify_token, :sign_out]

  # GET /sign_in
  def sign_in
    Rails.logger.info "=== Sign-in page accessed ==="
    Rails.logger.info "Session user_id: #{session[:user_id]}"
    Rails.logger.info "User signed in: #{user_signed_in?}"
    
    if user_signed_in?
      Rails.logger.info "User already signed in, redirecting to home"
      redirect_to pages_home_path
      return
    end
    
    Rails.logger.info "User not signed in, showing sign-in form"
    respond_to do |format|
      format.html # renders sign_in.html.erb
    end
  end

  # GET /sign_up  
  def sign_up
    redirect_to pages_home_path if user_signed_in?
    
    respond_to do |format|
      format.html # renders sign_up.html.erb
    end
  end

  # POST /auth/verify_token
  def verify_token
    Rails.logger.info "=== Firebase Token Verification Started ==="
    id_token = params[:id_token]
    
    if id_token.blank?
      Rails.logger.error "No token provided in request"
      render json: { success: false, error: 'No token provided' }, status: :bad_request
      return
    end

    Rails.logger.info "Token received, verifying with Firebase..."

    begin
      firebase_service = FirebaseAuthService.new
      decoded_token = firebase_service.verify_id_token(id_token)
      Rails.logger.info "Token verified successfully: #{decoded_token['email']}"
      
      # Find or create user from Firebase token
      Rails.logger.info "🔍 Token contains: Email=#{decoded_token['email']}, UID=#{decoded_token['uid']}"
      user = firebase_service.find_or_create_user_from_token(decoded_token)
      Rails.logger.info "🎯 User found/created: #{user.email} (ID: #{user.id})"
      Rails.logger.info "🆔 User Firebase UID: #{user.firebase_uid}"
      
      # Sign in the user
      sign_in_user(user)
      Rails.logger.info "🔐 User signed in to session: #{session[:user_id]}"
      Rails.logger.info "🔐 Session firebase_uid: #{session[:firebase_uid]}"
      
      response_data = { 
        success: true, 
        user: {
          id: user.id,
          email: user.email,
          firebase_uid: user.firebase_uid
        },
        redirect_url: pages_home_path
      }
      Rails.logger.info "Sending success response: #{response_data}"
      
      render json: response_data
    rescue FirebaseAuthService::InvalidTokenError => e
      Rails.logger.error "Firebase token verification failed: #{e.message}"
      render json: {
        success: false,
        error: 'Invalid authentication token'
      }, status: :unauthorized
    rescue => e
      Rails.logger.error "Authentication error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: {
        success: false,
        error: 'Authentication failed'
      }, status: :internal_server_error
    end
  end

  # DELETE /sign_out
  def sign_out
    sign_out_user
    
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Signed out successfully' }
      format.json { render json: { success: true, message: 'Signed out successfully' } }
    end
  end

  # DELETE /auth/delete_account
  def delete_account
    Rails.logger.info "=== Account Deletion Started ==="
    Rails.logger.info "User ID: #{current_user&.id}"
    Rails.logger.info "User Email: #{current_user&.email}"
    
    if current_user
      begin
        # Delete all associated data
        current_user.participants.destroy_all
        current_user.tasks.destroy_all
        current_user.households.destroy_all
        
        # Delete the user account
        user_email = current_user.email
        current_user.destroy!
        
        # Sign out the user
        sign_out_user
        
        Rails.logger.info "Account deleted successfully: #{user_email}"
        
        render json: { 
          success: true, 
          message: 'Account deleted successfully' 
        }
      rescue => e
        Rails.logger.error "Failed to delete account: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        
        render json: { 
          success: false, 
          error: 'Failed to delete account data' 
        }, status: :internal_server_error
      end
    else
      render json: { 
        success: false, 
        error: 'User not found' 
      }, status: :unauthorized
    end
  end

  private

  def sign_in_user(user)
    session[:user_id] = user.id
    session[:firebase_uid] = user.firebase_uid
    @current_user = user
  end

  def sign_out_user
    session[:user_id] = nil
    session[:firebase_uid] = nil
    @current_user = nil
  end
end