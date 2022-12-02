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

    test "starts the view state manager" do
      assert Process.whereis(Juvet.ViewStateManager) |> Process.alive?()
    end

    test "starts the Superintendent" do
      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    test "starts the FactorySupervisor" do
      # ensure process is started after Superintendent
      :timer.sleep(500)

      [{id, pid, type, [modules]} | _] = Supervisor.which_children(Juvet.BotFactory)

      assert id == Juvet.FactorySupervisor
      assert Process.alive?(pid)
      assert type == :supervisor
      assert [modules] == [Juvet.FactorySupervisor]
    end
  end

  describe "Juvet.start_bot!/3" do
    test "starts a new process for the bot" do
      bot = Juvet.start_bot!("Jimmy", :slack, %{team_id: "T12345"})

      assert Process.alive?(bot)
    end

    test "adds the platform to the bot" do
      bot = Juvet.start_bot!("Robert", :slack, %{team_id: "T12345"})

      :timer.sleep(500)

      %{platforms: platforms} = MyBot.get_state(bot)

      assert List.first(platforms).name == :slack
      assert List.first(List.first(platforms).messages) == %{team_id: "T12345"}
    end
  end

  describe "Juvet.configuration/0" do
    test "returns the configuration specified in the application" do
      assert Juvet.configuration() == Application.get_all_env(:juvet)
    end
  end
end
