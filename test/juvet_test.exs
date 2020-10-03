defmodule Juvet.JuvetTest do
  use ExUnit.Case

  import Juvet.ProcessHelpers
  import Juvet.ConfigurationHelpers

  setup_all :setup_with_supervised_application!
  setup_all :setup_reset_config_on_exit

  describe "Juvet.start/2 with valid configuration" do
    test "starts the BotFactory" do
      assert Process.whereis(Juvet.BotFactory) |> Process.alive?()
    end

    test "starts the Superintendent" do
      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    test "starts the BotSupervisor" do
      # ensure process is started after Superintendent
      :timer.sleep(500)

      [{id, pid, type, [modules]} | _] =
        Supervisor.which_children(Juvet.BotFactory)

      assert id == Juvet.BotSupervisor
      assert Process.alive?(pid)
      assert type == :supervisor
      assert [modules] == [Juvet.BotSupervisor]
    end
  end

  describe "Juvet.start/2 with invalid configuration" do
    setup :setup_reset_config

    test "does not start the BotSupervisor" do
      Application.put_env(:juvet, :bot, nil)

      # ensure process is started after Superintendent
      :timer.sleep(500)

      children = Supervisor.which_children(Juvet.BotFactory)

      IO.inspect(children)
    end
  end
end
