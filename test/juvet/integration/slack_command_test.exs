defmodule Juvet.Integration.SlackCommandTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      command("/test", to: "juvet.integration.slack_command_test.test#action")
      action("test_id", to: "controller#action")
    end
  end

  defmodule TestController do
    def action(%{pid: pid} = context) do
      send(pid, :called_controller)

      {:ok, context}
    end
  end

  def fixture(:valid_slack_command) do
    [
      {"token", "SLACK_TOKEN"},
      {"team_id", "T1234"},
      {"command", "/test"},
      {"text", ""}
    ]
    |> Enum.into(%{})
  end

  describe "with a valid Slack command" do
    setup do
      signing_secret = generate_slack_signing_secret()

      [signing_secret: signing_secret]
    end

    test "is routed correctly", %{signing_secret: signing_secret} do
      params = fixture(:valid_slack_command)

      conn =
        request!(
          :post,
          "/slack/commands",
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
