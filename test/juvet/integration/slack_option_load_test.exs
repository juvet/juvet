defmodule Juvet.Integration.SlackOptionLoadTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      option_load("menu",
        to: "juvet.integration.slack_option_load_test.test#options"
      )
    end
  end

  defmodule TestController do
    def options(%{pid: pid} = context) do
      send(pid, :called_controller)

      {:ok, context}
    end
  end

  def fixture(:valid_option_load, action_id \\ "ACTION") do
    payload =
      [
        {"type", "block_suggestion"},
        {"action_id", action_id},
        {"team", %{id: "T1234"}},
        {"user", %{id: "U1234"}},
        {"is_cleared", true}
      ]
      |> Enum.into(%{})
      |> Poison.encode!()

    [
      {"payload", payload}
    ]
    |> Enum.into(%{})
  end

  describe "with a valid Slack action" do
    setup do
      signing_secret = generate_slack_signing_secret()

      [signing_secret: signing_secret]
    end

    test "is routed correctly", %{signing_secret: signing_secret} do
      params = fixture(:valid_option_load, "menu")

      conn =
        request!(
          :post,
          "/slack/options",
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
