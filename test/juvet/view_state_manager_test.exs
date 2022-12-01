defmodule Juvet.ViewStateManagerTest do
  use ExUnit.Case, async: false

  alias Juvet.{ViewStateManager, ViewStateRegistry}

  describe "start_link/0" do
    test "returns the pid" do
      if Process.whereis(ViewStateManager.name()), do: ViewStateManager.stop()

      assert {:ok, pid} = ViewStateManager.start_link()
      assert is_pid(pid)
    end
  end

  describe "store/3" do
    setup do
      ViewStateManager.start_link()

      if !Process.whereis(ViewStateRegistry.name()), do: ViewStateRegistry.start_link()

      :ok
    end

    test "starts a view state process for a specific key" do
      key = {"T1234", "U1234", "C1234", :update_participants}

      assert {:ok, pid} = ViewStateManager.store(key, %{some: "value"})
      assert is_pid(pid)
      assert Process.alive?(pid)

      assert ViewStateManager.state(key) == %Juvet.ViewState{
               pid: pid,
               key: key,
               value: %{some: "value"}
             }
    end

    test "updates a view if it already exists" do
      key = {"T1234", "U1234", "C1234", :update_participants}

      {:ok, first_pid} = ViewStateManager.store(key, %{some: "value"})
      {:ok, second_pid} = ViewStateManager.store(key, %{other: "changed"})

      assert first_pid == second_pid
    end
  end
end
