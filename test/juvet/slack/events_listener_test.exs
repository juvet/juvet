defmodule Juvet.Slack.EventsListenerTest do
  use ExUnit.Case, async: false

  describe "Juvet.Slack.EventsListener.start_link/1" do
    test "starts an http server to listen for events" do
      Juvet.Slack.EventsListener.start_link()

      assert Process.whereis(Juvet.Slack.EventsListener) |> Process.alive?()
    end
  end
end
