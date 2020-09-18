defmodule Juvet.JuvetTest do
  use ExUnit.Case

  import Juvet.ProcessHelpers

  describe "Juvet.start/2" do
    setup :setup_with_supervised_application!

    test "starts the pub sub process" do
      assert Process.whereis(PubSub) |> Process.alive?()
    end

    test "starts the bot factory supervisor" do
      assert Process.whereis(Juvet.BotFactorySupervisor) |> Process.alive?()
    end

    test "starts the BotShop" do
      assert Process.whereis(Juvet.BotShop) |> Process.alive?()
    end

    test "starts the Endpoint" do
      assert Process.whereis(Juvet.Endpoint) |> Process.alive?()
    end
  end

  describe "Juvet.start/2 with Slack configured" do
    setup do
      config = Application.get_all_env(:juvet)

      on_exit(fn ->
        Application.put_all_env([{:juvet, config}])
      end)
    end

    test "starts Slack.EventsListener" do
      Application.put_env(:juvet, :slack, events_endpoint: "/slack/events")

      start_supervised_application!()

      assert Process.whereis(Juvet.Slack.EventsListener) |> Process.alive?()
    end
  end
end
