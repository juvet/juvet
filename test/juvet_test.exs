defmodule Juvet.JuvetTest do
  use ExUnit.Case, async: false

  describe "Juvet.start/2" do
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

      Application.stop(:juvet)

      on_exit(fn ->
        Application.stop(:juvet)
        Application.put_all_env([{:juvet, config}])
        Application.start(:juvet)
      end)
    end

    test "starts Slack.EventsListener" do
      Application.put_env(:juvet, :slack, events_endpoint: "/slack/events")

      Application.start(:juvet)

      assert Process.whereis(Juvet.Slack.EventsListener) |> Process.alive?()
    end
  end
end
