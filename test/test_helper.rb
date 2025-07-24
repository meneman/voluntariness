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
  # For our custom Firebase auth, we'll set up the session properly
  def sign_in(user)
    # Create a session state that matches what the app expects
    @user_for_auth = user
    
    # Override the session method to include our user data when accessed
    def session
      super.merge(user_id: @user_for_auth&.id, firebase_uid: @user_for_auth&.firebase_uid)
    end
  end
  
  def sign_out
    @user_for_auth = nil
  end
end
