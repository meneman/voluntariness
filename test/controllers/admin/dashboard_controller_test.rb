require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @admin_user = users(:admin)
    # Skip tests if no admin user exists
    skip "No admin user available" unless @admin_user&.admin?
    sign_in @admin_user
  end

  test "should get index" do
    get admin_root_path
    assert_response :success
  end
end
