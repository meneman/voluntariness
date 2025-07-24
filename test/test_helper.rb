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

# Add authentication helpers for custom Firebase auth  
class ActionDispatch::IntegrationTest
  # For our custom Firebase auth, set session directly like ActionController::TestCase
  def sign_in(user)
    if user
      # Initialize a request first to ensure session is available  
      get root_path
      # Then set session variables directly
      session[:user_id] = user.id
      session[:firebase_uid] = user.firebase_uid
    end
  end
  
  def sign_out(user = nil)
    session[:user_id] = nil
    session[:firebase_uid] = nil
  end
end

# Add same helpers for ActionController::TestCase
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
