defmodule Juvet.BotState.TeamTest do
  use ExUnit.Case

  setup_all do
    [state: %Juvet.BotState.Team{id: "T1234"}]
  end

  describe "Juvet.BotState.Team.from_ueberauth/1" do
    setup do
      auth = %{
        credentials: %{
          other: %{
            team_id: "T1234",
            team: "Zeppelin",
            team_url: "https://zeppelin.slack.com"
          },
          token: "SLACK_TOKEN",
          scopes: ["identify"]
        }
      }

      {:ok, auth: auth}
    end

    test "returns a struct based on the ueberauth data", %{auth: auth} do
      team = Juvet.BotState.Team.from_ueberauth(auth)

      assert team.id == "T1234"
      assert team.name == "Zeppelin"
      assert team.url == "https://zeppelin.slack.com"
      assert team.token == "SLACK_TOKEN"
      assert team.scopes == ["identify"]
    end
  end

  describe "Juvet.BotState.Team.put_user/2" do
    test "adds the user to the list of users", %{state: state} do
      {state, user} = Juvet.BotState.Team.put_user(state, %{id: "U1234"})

      assert state.users == [%Juvet.BotState.User{id: "U1234"}]
      assert user == %Juvet.BotState.User{id: "U1234"}
    end

    test "does not duplicate the user if it already exists", %{state: state} do
      {state, _user} = Juvet.BotState.Team.put_user(state, %{id: "U1234"})
      {state, user} = Juvet.BotState.Team.put_user(state, %{id: "U1234"})

      assert state.users == [%Juvet.BotState.User{id: "U1234"}]
      assert user == %Juvet.BotState.User{id: "U1234"}
    end

    test "updates the user values if it already exists", %{state: state} do
      {state, _user} =
        Juvet.BotState.Team.put_user(state, %{id: "U1234", name: "Jimmy Page"})

      {state, user} =
        Juvet.BotState.Team.put_user(state, %{id: "U1234", name: "Jimmy"})

      assert state.users == [%Juvet.BotState.User{id: "U1234", name: "Jimmy"}]
      assert user == %Juvet.BotState.User{id: "U1234", name: "Jimmy"}
    end
  end

  describe "Juvet.BotState.Team.has_user?/2" do
    test "returns false if the user does not exist", %{state: state} do
      refute Juvet.BotState.Team.has_user?(state, "U1234")
    end

    test "returns true if the user does exist", %{state: state} do
      {state, _user} = Juvet.BotState.Team.put_user(state, %{id: "U1234"})

      assert Juvet.BotState.Team.has_user?(state, "U1234")
    end
  end

  describe "Juvet.BotState.Team.user/2" do
    test "returns the state for the specified user", %{state: state} do
      {state, _user} = Juvet.BotState.Team.put_user(state, %{id: "U1234"})

      assert %Juvet.BotState.User{} = Juvet.BotState.Team.user(state, "U1234")
    end

    test "returns nil if the user does not exist", %{state: state} do
      assert Juvet.BotState.Team.user(state, "U1234") == nil
    end
  end
end
