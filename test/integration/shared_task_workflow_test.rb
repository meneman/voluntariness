require "test_helper"

class SharedTaskWorkflowTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @alice = participants(:alice)
    @bob = participants(:bob)
    @task = tasks(:dishwashing)
    
    # Clear existing action_participants to avoid conflicts
    ActionParticipant.destroy_all
    
    sign_in @user
  end

  test "should create action with single participant" do
    assert_difference 'Action.count', 1 do
      assert_difference 'ActionParticipant.count', 1 do
        post actions_path, params: {
          data: {
            task_id: @task.id,
            participant_id: @alice.id
          }
        }
      end
    end
    
    action = Action.last
    assert_equal 1, action.participants.count
    assert_includes action.participants, @alice
    
    action_participant = action.action_participants.first
    assert_equal @task.worth, action_participant.points_earned
    assert_not_nil action_participant.bonus_points
  end

  test "should create action with multiple participants" do
    assert_difference 'Action.count', 1 do
      assert_difference 'ActionParticipant.count', 2 do
        post actions_path, params: {
          data: {
            task_id: @task.id,
            participant_ids: [@alice.id, @bob.id]
          }
        }
      end
    end
    
    action = Action.last
    assert_equal 2, action.participants.count
    assert_includes action.participants, @alice
    assert_includes action.participants, @bob
    
    # Both participants should have their own action_participant record
    alice_ap = action.action_participants.find_by(participant: @alice)
    bob_ap = action.action_participants.find_by(participant: @bob)
    
    assert_not_nil alice_ap
    assert_not_nil bob_ap
    assert_equal @task.worth, alice_ap.points_earned
    assert_equal @task.worth, bob_ap.points_earned
  end

  test "should handle backward compatibility for participant method" do
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_id: @alice.id
      }
    }
    
    action = Action.last
    
    # Backward compatibility: action.participant should return first participant
    assert_equal @alice, action.participant
    
    # Backward compatibility: action.bonus_points should return first participant's bonus
    expected_bonus = @task.calculate_bonus_points
    assert_equal expected_bonus, action.bonus_points
  end

  test "should update participant points correctly" do
    initial_alice_points = @alice.total_points.to_f
    initial_bob_points = @bob.total_points.to_f
    
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_ids: [@alice.id, @bob.id]
      }
    }
    
    @alice.reload
    @bob.reload
    
    # Both participants should have increased points
    assert @alice.total_points.to_f > initial_alice_points
    assert @bob.total_points.to_f > initial_bob_points
  end

  test "should allow deleting shared action" do
    # Create a shared action
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_ids: [@alice.id, @bob.id]
      }
    }
    
    action = Action.last
    action_participant_count = action.action_participants.count
    
    assert_difference 'Action.count', -1 do
      assert_difference 'ActionParticipant.count', -action_participant_count do
        delete action_path(action)
      end
    end
  end

  test "should prevent adding participants from different users" do
    other_user = users(:two)
    other_participant = participants(:user_two_participant)
    
    # Try to add participant from different user
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_ids: [@alice.id, other_participant.id]
      }
    }
    
    # Should redirect with error (controller validates this)
    assert_redirected_to root_path
  end

  test "should handle empty participant list gracefully" do
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_ids: []
      }
    }
    
    # Should create action but with no participants
    action = Action.last
    assert_equal 0, action.participants.count if action
  end

  test "should validate participants belong to current user" do
    # Clear participants that might belong to other users
    participant_ids = [@alice.id, @bob.id]
    
    # Ensure all participants belong to the current user
    participants = Participant.where(id: participant_ids, household: @user.current_household)
    assert_equal 2, participants.count
    
    post actions_path, params: {
      data: {
        task_id: @task.id,
        participant_ids: participant_ids
      }
    }
    
    action = Action.last
    action.participants.each do |participant|
      assert_equal @user.current_household, participant.household
    end
  end

  # Use the sign_in method from test_helper.rb
end