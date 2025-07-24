require "test_helper"

class UseableItemsControllerTest < ActionDispatch::IntegrationTest
  # include Devise::Test::IntegrationHelpers


  def setup
    @user = users(:one)
    @participant = participants(:alice)
    @useable_item = useable_items(:crown)
    sign_in @user
  end

  test "should get index with participant_id" do
    get useable_items_url(participant_id: @participant.id)
    assert_response :success
  end

  test "should get show" do
    get useable_item_url(@useable_item)
    assert_response :success
  end

  test "should create useable item" do
    assert_difference("UseableItem.count") do
      post useable_items_url, params: {
        participant_id: @participant.id,
        item_name: "Magic Wand"
      }
    end
    assert_redirected_to useable_items_url(participant_id: @participant.id)
  end

  test "should destroy useable item" do
    assert_difference("UseableItem.count", -1) do
      delete useable_item_url(@useable_item)
    end
    assert_redirected_to useable_items_url(participant_id: @participant.id)
  end
end
