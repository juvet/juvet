defmodule Juvet.Slack.EventsListenerTest do
  use ExUnit.Case, async: false

  describe "Juvet.Slack.EventsListener.start_link/1" do
    test "starts an http server to listen for events" do
      config = [slack: [events_endpoint: "slack/events"]]

      Juvet.Slack.EventsListener.start_link(config)
    end
  end
end
