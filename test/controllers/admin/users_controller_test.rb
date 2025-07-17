require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @admin_user = users(:admin)
    # Skip tests if no admin user exists
    skip "No admin user available" unless @admin_user&.admin?
    sign_in @admin_user
  end

  test "should get index" do
    get admin_users_path
    assert_response :success
  end

  test "should get show" do
    get admin_user_path(@user)
    assert_response :success
  end

  test "should get edit" do
    get edit_admin_user_path(@user)
    assert_response :success
  end

  test "should update user" do
    patch admin_user_path(@user), params: { user: { name: "Updated Name" } }
    assert_response :redirect
  end

  test "should destroy user" do
    delete admin_user_path(@user)
    assert_response :redirect
  end
end
