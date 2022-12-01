defmodule Juvet.ViewStateRegistryTest do
  use ExUnit.Case, async: false

  alias Juvet.ViewStateRegistry

  setup_all do
    if Process.whereis(ViewStateRegistry.name()), do: ViewStateRegistry.stop()

    :ok
  end

  describe "start_link" do
    test "returns the pid" do
      assert {:ok, pid} = ViewStateRegistry.start_link()
      assert is_pid(pid)
    end
  end

  describe "register_name/2" do
    setup do
      ViewStateRegistry.start_link()

      :ok
    end

    test "registers the name with the pid for lookup" do
      :ok = ViewStateRegistry.register_name({:this, :is, :a, :key}, self())

      pid = ViewStateRegistry.whereis_name({:this, :is, :a, :key})

      assert pid == self()
    end

    test "does not register a name again that already exists" do
      assert :ok = ViewStateRegistry.register_name({:this, :is, :a, :key}, self())

      assert :already_registered =
               ViewStateRegistry.register_name(
                 {:this, :is, :a, :key},
                 spawn(fn -> nil end)
               )
    end

    test "removes the name when the process dies" do
      name = {:another, :key}

      pid = spawn(fn -> nil end)

      :ok = ViewStateRegistry.register_name(name, pid)

      pid |> Process.exit(:kill)

      assert :undefined = ViewStateRegistry.whereis_name(name)
    end
  end

  describe "send/2" do
    setup do
      ViewStateRegistry.start_link()

      :ok
    end

    test "sends the process a message based on the name" do
      name = {:send, :me, :a, :message}
      :ok = ViewStateRegistry.register_name(name, self())

      pid = ViewStateRegistry.send(name, :message)

      assert pid == self()
      assert_received :message
    end

    test "does not send a message if the process cannot be found" do
      name = {:send, :me, :a, :message}
      :ok = ViewStateRegistry.register_name(name, self())
      :ok = ViewStateRegistry.unregister_name(name)

      assert {:badarg, {^name, :message}} = ViewStateRegistry.send(name, :message)
    end
  end

  describe "unregister_name/1" do
    setup do
      ViewStateRegistry.start_link()

      :ok
    end

    test "removes the name from lookup" do
      name = {:this, :key, :works}
      :ok = ViewStateRegistry.register_name(name, self())

      assert :ok = ViewStateRegistry.unregister_name(name)
      assert :undefined = ViewStateRegistry.whereis_name(name)
    end
  end
end
