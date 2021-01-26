defmodule Juvet.BotStateTest do
  use ExUnit.Case

  setup_all do
    [state: %Juvet.BotState{}]
  end

  describe "Juvet.BotState.put_platform/2" do
    test "adds the platform to the list of platforms if it does not exist", %{
      state: state
    } do
      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      assert state.platforms == [%Juvet.PlatformState{name: :slack}]
      assert platform == %Juvet.PlatformState{name: :slack}
    end

    test "does not duplicate the platform if it already exists in the list", %{
      state: state
    } do
      {state, _platform} = Juvet.BotState.put_platform(state, :slack)
      {state, platform} = Juvet.BotState.put_platform(state, :slack)

      assert state.platforms == [%Juvet.PlatformState{name: :slack}]
      assert platform == %Juvet.PlatformState{name: :slack}
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

      assert %Juvet.PlatformState{} = Juvet.BotState.platform(state, :slack)
    end

    test "returns nil if the platform does not exist", %{state: state} do
      assert Juvet.BotState.platform(state, :slack) == nil
    end
  end
end
