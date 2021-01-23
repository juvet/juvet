defmodule Juvet.TeamStateTest do
  use ExUnit.Case

  setup_all do
    [state: %Juvet.TeamState{}]
  end

  describe "Juvet.TeamState.add_user/2" do
    test "adds the user to the list of users", %{state: state} do
      state = Juvet.TeamState.add_user(state, "U1234")

      assert state.users == [{"U1234", %Juvet.UserState{}}]
    end

    test "adds the user's attributes to the user's state", %{state: state} do
      state =
        Juvet.TeamState.add_user(state, "U1234",
          first_name: "Jimmy",
          blah: "bleh"
        )

      assert state == %Juvet.TeamState{
               users: [{"U1234", %Juvet.UserState{first_name: "Jimmy"}}]
             }
    end

    test "does not duplicate the user if it already exists", %{state: state} do
      state = Juvet.TeamState.add_user(state, "U1234")
      state = Juvet.TeamState.add_user(state, "U1234")

      assert state.users == [{"U1234", %Juvet.UserState{}}]
    end
  end

  describe "Juvet.TeamState.has_user?/2" do
    test "returns false if the user does not exist", %{state: state} do
      refute Juvet.TeamState.has_user?(state, "U1234")
    end

    test "returns true if the user does exist", %{state: state} do
      state = Juvet.TeamState.add_user(state, "U1234")

      assert Juvet.TeamState.has_user?(state, "U1234")
    end
  end

  describe "Juvet.TeamState.user/2" do
    test "returns the state for the specified user", %{state: state} do
      state = Juvet.TeamState.add_user(state, "U1234")

      assert %Juvet.UserState{} = Juvet.TeamState.user(state, "U1234")
    end

    test "returns nil if the user does not exist", %{state: state} do
      assert Juvet.TeamState.user(state, "U1234") == nil
    end
  end
end
