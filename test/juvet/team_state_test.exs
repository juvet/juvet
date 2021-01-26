defmodule Juvet.TeamStateTest do
  use ExUnit.Case

  setup_all do
    [state: %Juvet.TeamState{id: "T1234"}]
  end

  describe "Juvet.TeamState.put_user/2" do
    test "adds the user to the list of users", %{state: state} do
      {state, user} = Juvet.TeamState.put_user(state, %{id: "U1234"})

      assert state.users == [%Juvet.UserState{id: "U1234"}]
      assert user == %Juvet.UserState{id: "U1234"}
    end

    test "does not duplicate the user if it already exists", %{state: state} do
      {state, _user} = Juvet.TeamState.put_user(state, %{id: "U1234"})
      {state, user} = Juvet.TeamState.put_user(state, %{id: "U1234"})

      assert state.users == [%Juvet.UserState{id: "U1234"}]
      assert user == %Juvet.UserState{id: "U1234"}
    end

    test "updates the user values if it already exists", %{state: state} do
      {state, _user} =
        Juvet.TeamState.put_user(state, %{id: "U1234", name: "Jimmy Page"})

      {state, user} =
        Juvet.TeamState.put_user(state, %{id: "U1234", name: "Jimmy"})

      assert state.users == [%Juvet.UserState{id: "U1234", name: "Jimmy"}]
      assert user == %Juvet.UserState{id: "U1234", name: "Jimmy"}
    end
  end

  describe "Juvet.TeamState.has_user?/2" do
    test "returns false if the user does not exist", %{state: state} do
      refute Juvet.TeamState.has_user?(state, "U1234")
    end

    test "returns true if the user does exist", %{state: state} do
      {state, _user} = Juvet.TeamState.put_user(state, %{id: "U1234"})

      assert Juvet.TeamState.has_user?(state, "U1234")
    end
  end

  describe "Juvet.TeamState.user/2" do
    test "returns the state for the specified user", %{state: state} do
      {state, _user} = Juvet.TeamState.put_user(state, %{id: "U1234"})

      assert %Juvet.UserState{} = Juvet.TeamState.user(state, "U1234")
    end

    test "returns nil if the user does not exist", %{state: state} do
      assert Juvet.TeamState.user(state, "U1234") == nil
    end
  end
end
