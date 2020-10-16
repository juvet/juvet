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

    @tag :skip
    test "starts the Superintendent" do
      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    @tag :skip
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
end
