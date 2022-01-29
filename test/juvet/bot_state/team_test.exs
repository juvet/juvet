defmodule Juvet.BotState.TeamTest do
  use ExUnit.Case

  alias Juvet.BotState.{Team, User}

  setup_all do
    [state: %Team{id: "T1234"}]
  end

  describe "from_auth/1" do
    setup do
      auth = %{
        access_token: "BOT_TOKEN",
        authed_user: %{
          id: "U12345"
        },
        bot_user_id: "UBOT",
        scope: "users:read,team:read",
        team: %{id: "T1234", name: "Zeppelin"},
        token_type: "bot"
      }

      {:ok, auth: auth}
    end

    test "returns a struct based on the auth data", %{auth: auth} do
      team = Team.from_auth(auth)

      assert team.id == "T1234"
      assert team.name == "Zeppelin"
      assert team.token == "BOT_TOKEN"
      assert team.scopes == "users:read,team:read"
    end
  end

  describe "put_user/2" do
    test "adds the user to the list of users", %{state: state} do
      {state, user} = Team.put_user(state, %{id: "U1234"})

      assert state.users == [%User{id: "U1234"}]
      assert user == %User{id: "U1234"}
    end

    test "does not duplicate the user if it already exists", %{state: state} do
      {state, _user} = Team.put_user(state, %{id: "U1234"})
      {state, user} = Team.put_user(state, %{id: "U1234"})

      assert state.users == [%User{id: "U1234"}]
      assert user == %User{id: "U1234"}
    end

    test "updates the user values if it already exists", %{state: state} do
      {state, _user} = Team.put_user(state, %{id: "U1234", name: "Jimmy Page"})

      {state, user} = Team.put_user(state, %{id: "U1234", name: "Jimmy"})

      assert state.users == [%User{id: "U1234", name: "Jimmy"}]
      assert user == %User{id: "U1234", name: "Jimmy"}
    end
  end

  describe "has_user?/2" do
    test "returns false if the user does not exist", %{state: state} do
      refute Team.has_user?(state, "U1234")
    end

    test "returns true if the user does exist", %{state: state} do
      {state, _user} = Team.put_user(state, %{id: "U1234"})

      assert Team.has_user?(state, "U1234")
    end
  end

  describe "user/2" do
    test "returns the state for the specified user", %{state: state} do
      {state, _user} = Team.put_user(state, %{id: "U1234"})

      assert %User{} = Team.user(state, "U1234")
    end

    test "returns nil if the user does not exist", %{state: state} do
      assert Team.user(state, "U1234") == nil
    end
  end
end
