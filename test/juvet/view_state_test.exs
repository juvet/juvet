defmodule Juvet.ViewStateTest do
  use ExUnit.Case, async: false

  alias Juvet.{ViewState, ViewStateRegistry}

  setup_all do
    ViewStateRegistry.start_link()

    :ok
  end

  describe "exists?/1" do
    setup do
      key = {:my, :unique, :key}

      {:ok, pid} = ViewState.start(key, "This is a value")

      on_exit(fn ->
        if ViewState.exists?(key), do: ViewState.stop(pid)
      end)

      [pid: pid, key: key]
    end

    test "returns true if the view state exists via key", %{key: key} do
      assert ViewState.exists?(key)
    end

    test "returns false if the view state does not exists via key", %{key: key} do
      ViewState.stop(key)

      refute ViewState.exists?(key)
    end
  end

  describe "start/3" do
    setup do
      key = {:key, :view, :state}

      on_exit(fn -> ViewState.stop(key) end)

      [key: key]
    end

    test "returns the pid", %{key: key} do
      assert {:ok, pid} = ViewState.start(key, :value)
      assert is_pid(pid)
    end
  end

  describe "state/1" do
    setup do
      key = {:my, :view, :state}

      on_exit(fn -> ViewState.stop(key) end)

      [key: key]
    end

    test "returns the state via pid", %{key: key} do
      {:ok, pid} = ViewState.start(key, :value)

      state = ViewState.state(pid)

      assert %ViewState{
               pid: pid,
               key: key,
               value: :value
             } == state
    end

    test "returns the state via key", %{key: key} do
      {:ok, pid} = ViewState.start(key, :value)

      state = ViewState.state(key)

      assert %ViewState{
               pid: pid,
               key: key,
               value: :value
             } == state
    end
  end

  describe "stop/1" do
    setup do
      {:ok, pid} = ViewState.start(:key, :value)

      [pid: pid]
    end

    test "stops the process", %{pid: pid} do
      state = ViewState.stop(pid)

      refute Process.alive?(state.pid)
    end
  end

  describe "update/2" do
    setup do
      {:ok, pid} = ViewState.start({:my, :key}, "This is some value")

      on_exit(fn -> ViewState.stop(pid) end)

      [pid: pid]
    end

    test "updates the current value via pid", %{pid: pid} do
      ViewState.update(pid, "This is a new value")

      actual = ViewState.value(pid)

      assert actual == "This is a new value"
    end
  end

  describe "value/1" do
    setup do
      value = "This is stored"

      {:ok, pid} = ViewState.start({:my, :key}, value)

      on_exit(fn -> ViewState.stop(pid) end)

      [pid: pid, value: value]
    end

    test "returns the current value via pid", %{pid: pid, value: value} do
      actual = ViewState.value(pid)

      assert actual == value
    end
  end
end
