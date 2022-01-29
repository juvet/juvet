defmodule Juvet.BotState.PlatformTest do
  use ExUnit.Case

  alias Juvet.BotState.{Platform, Team}

  setup_all do
    [state: %Juvet.BotState.Platform{name: :slack}]
  end

  describe "get_messages/1" do
    test "returns all the messages for a platform", %{state: state} do
      message1 = %{text: "Message #1"}
      message2 = %{text: "Message #2"}

      {state, _message} = Platform.put_message(state, message1)
      {state, _message} = Platform.put_message(state, message2)

      assert Platform.get_messages(state) == [message1, message2]
    end
  end

  describe "put_message/2" do
    test "adds the message to the list of messages", %{state: state} do
      {state, message} = Platform.put_message(state, %{text: "Hello World"})

      assert state.messages == [%{text: "Hello World"}]
      assert message == %{text: "Hello World"}
    end
  end

  describe "put_team/2" do
    test "adds the team to the list of teams", %{state: state} do
      {state, team} = Platform.put_team(state, %{id: "T1234"})

      assert state.teams == [%Team{id: "T1234"}]
      assert team == %Team{id: "T1234"}
    end

    test "does not duplicate the team if it already exists", %{state: state} do
      {state, _team} = Platform.put_team(state, %{id: "T1234"})
      {state, team} = Platform.put_team(state, %{id: "T1234"})

      assert state.teams == [%Team{id: "T1234"}]
      assert team == %Team{id: "T1234"}
    end

    test "updates the team values if it already exists", %{state: state} do
      {state, _team} =
        Platform.put_team(state, %{
          id: "T1234",
          name: "Led Zeppelin"
        })

      {state, team} = Platform.put_team(state, %{id: "T1234", name: "Zeppelin"})

      assert state.teams == [
               %Team{id: "T1234", name: "Zeppelin"}
             ]

      assert team == %Team{id: "T1234", name: "Zeppelin"}
    end
  end

  describe "has_team?/2" do
    test "returns false if the team does not exist", %{state: state} do
      refute Platform.has_team?(state, "T1234")
    end

    test "returns true if the team does exist", %{state: state} do
      {state, _team} = Platform.put_team(state, %{id: "T1234"})

      assert Platform.has_team?(state, "T1234")
    end
  end

  describe "team/2" do
    test "returns the state for the specified team", %{state: state} do
      {state, _team} = Platform.put_team(state, %{id: "T1234"})

      assert %Team{} = Platform.team(state, "T1234")
    end

    test "returns nil if the team does not exist", %{state: state} do
      assert Platform.team(state, "T1234") == nil
    end
  end
end
