require "test_helper"

class HouseholdsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get households_index_url
    assert_response :success
  end

  test "should get show" do
    get households_show_url
    assert_response :success
  end

  test "should get new" do
    get households_new_url
    assert_response :success
  end

  test "should get create" do
    get households_create_url
    assert_response :success
  end

  test "should get edit" do
    get households_edit_url
    assert_response :success
  end

  test "should get update" do
    get households_update_url
    assert_response :success
  end

  test "should get destroy" do
    get households_destroy_url
    assert_response :success
  end

  test "should get switch_household" do
    get households_switch_household_url
    assert_response :success
  end

  test "should get join" do
    get households_join_url
    assert_response :success
  end
end
