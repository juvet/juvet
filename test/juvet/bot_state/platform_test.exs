defmodule Juvet.BotState.PlatformTest do
  use ExUnit.Case

  setup_all do
    [state: %Juvet.BotState.Platform{name: :slack}]
  end

  describe "Juvet.BotState.Platform.put_team/2" do
    test "adds the team to the list of teams", %{state: state} do
      {state, team} = Juvet.BotState.Platform.put_team(state, %{id: "T1234"})

      assert state.teams == [%Juvet.BotState.Team{id: "T1234"}]
      assert team == %Juvet.BotState.Team{id: "T1234"}
    end

    test "does not duplicate the team if it already exists", %{state: state} do
      {state, _team} = Juvet.BotState.Platform.put_team(state, %{id: "T1234"})
      {state, team} = Juvet.BotState.Platform.put_team(state, %{id: "T1234"})

      assert state.teams == [%Juvet.BotState.Team{id: "T1234"}]
      assert team == %Juvet.BotState.Team{id: "T1234"}
    end

    test "updates the team values if it already exists", %{state: state} do
      {state, _team} =
        Juvet.BotState.Platform.put_team(state, %{
          id: "T1234",
          name: "Led Zeppelin"
        })

      {state, team} =
        Juvet.BotState.Platform.put_team(state, %{id: "T1234", name: "Zeppelin"})

      assert state.teams == [
               %Juvet.BotState.Team{id: "T1234", name: "Zeppelin"}
             ]

      assert team == %Juvet.BotState.Team{id: "T1234", name: "Zeppelin"}
    end
  end

  describe "Juvet.BotState.Platform.has_team?/2" do
    test "returns false if the team does not exist", %{state: state} do
      refute Juvet.BotState.Platform.has_team?(state, "T1234")
    end

    test "returns true if the team does exist", %{state: state} do
      {state, _team} = Juvet.BotState.Platform.put_team(state, %{id: "T1234"})

      assert Juvet.BotState.Platform.has_team?(state, "T1234")
    end
  end

  describe "Juvet.BotState.Platform.team/2" do
    test "returns the state for the specified team", %{state: state} do
      {state, _team} = Juvet.BotState.Platform.put_team(state, %{id: "T1234"})

      assert %Juvet.BotState.Team{} =
               Juvet.BotState.Platform.team(state, "T1234")
    end

    test "returns nil if the team does not exist", %{state: state} do
      assert Juvet.BotState.Platform.team(state, "T1234") == nil
    end
  end
end
