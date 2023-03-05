defmodule Juvet.Integration.SlackEventTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      event("app_home_opened", to: "juvet.integration.slack_event_test.test#event")
    end
  end

  defmodule TestController do
    def event(%{pid: pid} = context) do
      send(pid, :called_controller)

      {:ok, context}
    end
  end

  def fixture(:valid_slack_event) do
    event = %{
      "type" => "app_home_opened",
      "user" => "U12345",
      "channel" => "C12345"
    }

    [
      {"token", "SLACK_TOKEN"},
      {"team_id", "T1234"},
      {"type", "event_callback"},
      {"event", event}
    ]
    |> Enum.into(%{})
  end

  describe "with a valid Slack event" do
    setup do
      signing_secret = generate_slack_signing_secret()

      [signing_secret: signing_secret]
    end

    test "is routed correctly", %{signing_secret: signing_secret} do
      params = fixture(:valid_slack_event)

      conn =
        request!(
          :post,
          "/slack/events",
          params,
          slack_headers(params, signing_secret),
          context: %{pid: self()},
          configuration: [
            router: MyRouter,
            slack: [signing_secret: signing_secret]
          ]
        )

      assert conn.status == 200
      # Request was successful and will not continue in the request chain
      assert conn.halted

      assert_received :called_controller
    end
  end
end
