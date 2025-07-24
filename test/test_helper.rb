ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Mock Firebase service for tests
class FirebaseAuthService
  def verify_id_token(token)
    # Extract user ID from mock token
    if token.start_with?("mock_firebase_token_")
      user_id = token.split("_").last.to_i
      user = User.find(user_id)
      return {
        'uid' => user.firebase_uid,
        'email' => user.email
      }
    end
    raise FirebaseAuthService::InvalidTokenError, "Invalid mock token"
  end
  
  def find_or_create_user_from_token(decoded_token)
    User.find_by(firebase_uid: decoded_token['uid'])
  end
  
  class InvalidTokenError < StandardError; end
end

# Add authentication helpers for custom Firebase auth  
class ActionDispatch::IntegrationTest
  def sign_in(user)
    if user
      # Use the actual authentication endpoint with mocked Firebase
      post auth_verify_token_path, 
           params: { id_token: "mock_firebase_token_#{user.id}" }.to_json,
           headers: { 'Content-Type' => 'application/json' }
    end
  end
  
  def sign_out(user = nil)
    delete sign_out_path
  end
end

# Add same helpers for ActionController::TestCase (this approach works)
class ActionController::TestCase
  def sign_in(user)
    if user
      session[:user_id] = user.id
      session[:firebase_uid] = user.firebase_uid
    end
  end
  
  def sign_out(user = nil)
    session[:user_id] = nil
    session[:firebase_uid] = nil
  end
end
