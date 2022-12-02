defmodule Juvet.ViewStateManagerTest do
  use ExUnit.Case, async: false

  alias Juvet.ViewStateManager

  describe "start_link/0" do
    test "returns the pid" do
      assert {:ok, pid} = start_supervised(ViewStateManager)
      assert is_pid(pid)
    end
  end

  describe "store/3" do
    setup do
      start_supervised!(ViewStateManager)
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
