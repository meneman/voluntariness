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
  def sign_in(user)
    # Mock the Firebase auth for testing by directly setting session
    if integration_session
      integration_session.session[:user_id] = user.id
      integration_session.session[:firebase_uid] = user.firebase_uid
    end
  end
  
  def sign_out
    if integration_session
      integration_session.session[:user_id] = nil
      integration_session.session[:firebase_uid] = nil
    end
  end
end
