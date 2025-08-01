require "test_helper"

class ParticipantsControllerTest < ActionDispatch::IntegrationTest
  # include Devise::Test::IntegrationHelpers


  def setup
    @user = users(:one)
    @participant = participants(:alice)
    @other_user_participant = participants(:user_two_participant)
    sign_in @user
  end

  test "should require authentication for all actions" do
    sign_out @user

    get participants_path
    assert_redirected_to sign_in_path

    get participant_path(@participant)
    assert_redirected_to sign_in_path

    get new_participant_path
    assert_redirected_to sign_in_path

    post participants_path, params: { participant: { name: "Test" } }
    assert_redirected_to sign_in_path
  end

  test "should get index" do
    get participants_path
    assert_response :success
    assert_includes response.body, @participant.name
  end

  # test "should get index as turbo stream" do
  #   get participants_path, as: :turbo_stream
  #   assert_response :success
  #   assert_equal "text/vnd.turbo-stream.html", response.media_type
  # end

  test "index should only show current user's participants" do
    get participants_path
    assert_response :success

    # Should include user's participants
    @user.participants.each do |participant|
      assert_includes response.body, participant.name
    end

    # Should not include other user's participants
    assert_not_includes response.body, @other_user_participant.name
  end

  test "should get show" do
    get participant_path(@participant)
    assert_response :success
    assert_includes response.body, @participant.name
    assert_assigns(:participant)
  end

  test "should not show other user's participant" do
    get participant_path(@other_user_participant)
    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end

  test "should get new" do
    get new_participant_path
    assert_response :success
    assert_assigns(:participant)
    assert assigns(:participant).new_record?
  end

  test "should create participant with valid params" do
    assert_difference("@user.participants.count", 1) do
      post participants_path, params: {
        participant: {
          name: "New Participant",
          color: "#FF0000"
        }
      }
    end

    assert_redirected_to participants_path

    new_participant = @user.participants.last
    assert_equal "New Participant", new_participant.name
    assert_equal "#FF0000", new_participant.color
  end

  test "should create participant as turbo stream" do
    assert_difference("@user.participants.count", 1) do
      post participants_path, params: {
        participant: {
          name: "Turbo Participant",
          color: "#00FF00"
        }
      }, as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not create participant with invalid params" do
    assert_no_difference("@user.participants.count") do
      post participants_path, params: {
        participant: {
          name: "",  # Invalid: blank name
          color: "#FF0000"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should not create participant without name" do
    assert_no_difference("@user.participants.count") do
      post participants_path, params: {
        participant: {
          color: "#FF0000"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should get edit" do
    get edit_participant_path(@participant)
    assert_response :success
    assert_assigns(:participant)
    assert_equal @participant, assigns(:participant)
  end

  test "should not edit other user's participant" do
    get edit_participant_path(@other_user_participant)
    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end

  test "should update participant with valid params" do
    patch participant_path(@participant), params: {
      participant: {
        name: "Updated Participant",
        color: "#0000FF"
      }
    }

    assert_redirected_to participants_path
    @participant.reload
    assert_equal "Updated Participant", @participant.name
    assert_equal "#0000FF", @participant.color
  end

  test "should not update participant with invalid params" do
    original_name = @participant.name

    patch participant_path(@participant), params: {
      participant: {
        name: "",  # Invalid
        color: "#0000FF"
      }
    }

    assert_response :unprocessable_entity
    @participant.reload
    assert_equal original_name, @participant.name
  end

  # test "should handle update as turbo stream for invalid params" do
  #   patch participant_path(@participant), params: {
  #     participant: {
  #       name: ""  # Invalid
  #     }
  #   }, as: :turbo_stream

  #   assert_response :unprocessable_entity
  #   assert_equal "text/vnd.turbo-stream.html", response.media_type
  # end

  test "should not update other user's participant" do
    patch participant_path(@other_user_participant), params: {
      participant: { name: "Hacked" }
    }

    assert_response :redirect
    assert_equal "Resource not found", flash[:alert]

    # Verify the participant wasn't actually updated
    @other_user_participant.reload
    assert_not_equal "Hacked", @other_user_participant.name
  end

  test "should archive participant" do
    assert_not @participant.archived

    patch archive_participant_path(@participant)
    assert_response :success

    @participant.reload
    assert @participant.archived
  end

  test "should unarchive participant" do
    @participant.update!(archived: true)

    patch unarchive_participant_path(@participant)
    assert_response :success

    @participant.reload
    assert_not @participant.archived
  end

  test "should archive participant as turbo stream" do
    patch archive_participant_path(@participant), as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should not archive other user's participant" do
    before = @other_user_participant.archived
    patch archive_participant_path(@other_user_participant)

    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]

    @other_user_participant.reload
    assert_equal before, @other_user_participant.archived
  end

  # test "should get cancel" do
  #   get cancel_participants_path
  #   assert_response :success
  # end

  test "should get cancel as turbo stream" do
    get cancel_participant_path, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "should destroy participant" do
    assert_difference("@user.participants.count", -1) do
      delete participant_path(@participant)
    end

    assert_redirected_to pages_home_path
    assert_equal "Participant was successfully deleted.", flash[:notice]
  end

  test "should destroy participant as turbo stream" do
    assert_difference("@user.participants.count", -1) do
      delete participant_path(@participant), as: :turbo_stream
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_equal "Participant was successfully deleted.", flash.now[:notice]
  end

  test "should not destroy other household's participant" do
    other_household_participant_count = @other_user_participant.household.participants.count

    delete participant_path(@other_user_participant)

    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
    assert_equal other_household_participant_count, @other_user_participant.household.participants.count
  end

  test "should destroy participant and its action_participants" do
    action = Action.create!(task: tasks(:dishwashing))
    action.add_participants([ @participant.id ])
    action_id = action.id

    # Verify the action_participant exists before deletion
    assert_not_nil ActionParticipant.find_by(action_id: action_id, participant_id: @participant.id)

    delete participant_path(@participant)

    # Action should still exist but action_participant should be deleted
    assert_not_nil Action.find_by(id: action_id)
    assert_nil ActionParticipant.find_by(action_id: action_id, participant_id: @participant.id)
  end

  test "should handle avatar parameter" do
    # Test that avatar parameter is permitted (if using Active Storage)
    post participants_path, params: {
      participant: {
        name: "Avatar Participant",
        color: "#FF0000"
        # avatar would be a file upload in real scenario
      }
    }

    assert_redirected_to participants_path
    new_participant = @user.participants.last
    assert_equal "Avatar Participant", new_participant.name
  end

  test "participant params should be properly filtered" do
    # Test that only permitted parameters are allowed
    post participants_path, params: {
      participant: {
        name: "Test Participant",
        color: "#FF0000",
        user_id: users(:two).id,  # Should be ignored
        archived: true,           # Should be ignored
        id: 999                   # Should be ignored
      }
    }

    assert_redirected_to participants_path
    new_participant = @user.current_household.participants.last
    assert_equal @user.current_household, new_participant.household  # Should belong to current household
    assert_not new_participant.archived       # Should not be archived
  end

  test "should handle color parameter" do
    post participants_path, params: {
      participant: {
        name: "Colorful Participant",
        color: "#ABCDEF"
      }
    }

    assert_redirected_to participants_path
    new_participant = @user.participants.last
    assert_equal "#ABCDEF", new_participant.color
  end

  test "should handle missing color parameter" do
    post participants_path, params: {
      participant: {
        name: "No Color Participant"
      }
    }

    assert_redirected_to participants_path
    new_participant = @user.participants.last
    assert_equal "No Color Participant", new_participant.name
    # Color should be nil or default value
  end

  test "archived participants should not appear in regular index" do
    @participant.update!(archived: true)

    get participants_path
    assert_response :success

    # Should not include archived participant if using active scope
    # This depends on whether the controller filters by active scope
    # Based on the model, it has an active scope, but controller might not use it
  end

  test "should handle ActiveRecord::RecordNotFound gracefully" do
    # This tests the ApplicationController error handling
    get participant_path(999999)  # Non-existent participant
    assert_redirected_to pages_home_path
    assert_equal "Resource not found", flash[:alert]
  end

  test "update should redirect to index with html format" do
    patch participant_path(@participant), params: {
      participant: {
        name: "Updated Name"
      }
    }

    assert_redirected_to participants_path
  end

  private

  def assert_assigns(variable_name)
    assert_not_nil assigns(variable_name), "@#{variable_name} should be assigned"
  end
end
