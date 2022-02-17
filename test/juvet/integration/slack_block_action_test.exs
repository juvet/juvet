defmodule Juvet.Integration.SlackBlockActionTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      action("test_action_id", to: "juvet.integration.slack_block_action_test.test#action")
    end
  end

  defmodule TestController do
    def action(%{pid: pid}) do
      send(pid, :called_controller)
    end
  end

  def fixture(:valid_slack_block_action) do
    payload =
      %{
        "type" => "block_actions",
        "actions" => "[{\"action_id\":\"test_action_id\"}]"
      }
      |> Poison.encode!()

    [
      {"token", "SLACK_TOKEN"},
      {"payload", payload}
    ]
    |> Enum.into(%{})
  end

  describe "with a valid Slack block action" do
    setup do
      signing_secret = generate_slack_signing_secret()

      [signing_secret: signing_secret]
    end

    test "is routed correctly", %{signing_secret: signing_secret} do
      params = fixture(:valid_slack_block_action)

      conn =
        request!(
          :post,
          "/slack/actions",
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
