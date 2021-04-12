defmodule Juvet.BotStateTest do
  use ExUnit.Case

  setup_all do
    [state: %Juvet.BotState{}]
  end

  describe "Juvet.BotState.get_messages/1" do
    test "retrieves all messages from all platforms", %{state: state} do
      message1 = %{text: "Message #1"}
      message2 = %{text: "Message #2"}

      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      {state, _platform, _message} =
        Juvet.BotState.put_message({state, platform}, message1)

      {state, platform} = Juvet.BotState.put_platform(state, :teams)

      {state, _platform, _message} =
        Juvet.BotState.put_message({state, platform}, message2)

      assert Juvet.BotState.get_messages(state) == [message1, message2]
    end
  end

  describe "Juvet.BotState.put_message/2" do
    test "adds the message to the specified platform if it does not exist", %{
      state: state
    } do
      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      {state, platform, message} =
        Juvet.BotState.put_message({state, platform}, %{text: "Hello"})

      assert state == %Juvet.BotState{
               platforms: [
                 %Juvet.BotState.Platform{
                   name: :slack,
                   messages: [%{text: "Hello"}]
                 }
               ]
             }

      assert platform == %Juvet.BotState.Platform{
               name: :slack,
               messages: [%{text: "Hello"}]
             }

      assert message == %{text: "Hello"}
    end

    test "does not change the state if the platform does not exist", %{
      state: state
    } do
      {new_state, platform, message} =
        Juvet.BotState.put_message({state, %{name: :slack}}, %{text: "Hello"})

      assert new_state == state
      assert platform == nil
      assert message == nil
    end
  end

  describe "Juvet.BotState.put_platform/2" do
    test "adds the platform to the list of platforms if it does not exist", %{
      state: state
    } do
      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      assert state.platforms == [%Juvet.BotState.Platform{name: :slack}]
      assert platform == %Juvet.BotState.Platform{name: :slack}
    end

    test "does not duplicate the platform if it already exists in the list", %{
      state: state
    } do
      {state, _platform} = Juvet.BotState.put_platform(state, :slack)
      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      assert state.platforms == [%Juvet.BotState.Platform{name: :slack}]
      assert platform == %Juvet.BotState.Platform{name: :slack}
    end
  end

  describe "Juvet.BotState.put_team/2" do
    test "adds the team to the specified platform if it does not exist", %{
      state: state
    } do
      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      {state, platform, team} =
        Juvet.BotState.put_team({state, platform}, %{id: "T1234"})

      assert state == %Juvet.BotState{
               platforms: [
                 %Juvet.BotState.Platform{
                   name: :slack,
                   teams: [%Juvet.BotState.Team{id: "T1234"}]
                 }
               ]
             }

      assert platform == %Juvet.BotState.Platform{
               name: :slack,
               teams: [%Juvet.BotState.Team{id: "T1234"}]
             }

      assert team == %Juvet.BotState.Team{id: "T1234"}
    end

    test "does not change the state if the platform does not exist", %{
      state: state
    } do
      {new_state, platform, team} =
        Juvet.BotState.put_team({state, %{name: :slack}}, %{id: "T1234"})

      assert new_state == state
      assert platform == nil
      assert team == nil
    end
  end

  describe "Juvet.BotState.put_user/2" do
    test "adds the user to the specified team if it does not exist", %{
      state: state
    } do
      {state, platform, team} =
        Juvet.BotState.put_platform(state, :slack)
        |> Juvet.BotState.put_team(%{id: "T1234"})

      {state, platform, team, user} =
        Juvet.BotState.put_user({state, platform, team}, %{id: "U1234"})

      assert state == %Juvet.BotState{
               platforms: [
                 %Juvet.BotState.Platform{
                   name: :slack,
                   teams: [
                     %Juvet.BotState.Team{
                       id: "T1234",
                       users: [%Juvet.BotState.User{id: "U1234"}]
                     }
                   ]
                 }
               ]
             }

      assert platform == %Juvet.BotState.Platform{
               name: :slack,
               teams: [
                 %Juvet.BotState.Team{
                   id: "T1234",
                   users: [%Juvet.BotState.User{id: "U1234"}]
                 }
               ]
             }

      assert team == %Juvet.BotState.Team{
               id: "T1234",
               users: [%Juvet.BotState.User{id: "U1234"}]
             }

      assert user == %Juvet.BotState.User{id: "U1234"}
    end

    test "does not change the state if the platform does not exist", %{
      state: state
    } do
      {new_state, platform, team, user} =
        Juvet.BotState.put_user({state, %{name: :slack}, %{id: "T1234"}}, %{
          id: "U1234"
        })

      assert new_state == state
      assert platform == nil
      assert team == nil
      assert user == nil
    end
  end

  describe "Juvet.BotState.has_platform?/2" do
    test "returns false if the platform does not exist", %{state: state} do
      refute Juvet.BotState.has_platform?(state, :slack)
    end

    test "returns true if the platform does exist", %{state: state} do
      {state, _platform} = Juvet.BotState.put_platform(state, :slack)

      assert Juvet.BotState.has_platform?(state, :slack)
    end
  end

  describe "Juvet.BotState.platform/2" do
    test "returns the state for the specified platform", %{state: state} do
      {state, _platform} = Juvet.BotState.put_platform(state, :slack)

      assert %Juvet.BotState.Platform{} = Juvet.BotState.platform(state, :slack)
    end

    test "returns nil if the platform does not exist", %{state: state} do
      assert Juvet.BotState.platform(state, :slack) == nil
    end
  end
end
