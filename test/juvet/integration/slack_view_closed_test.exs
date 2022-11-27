defmodule Juvet.Integration.SlackViewClosedTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      view_closed("closed",
        to: "juvet.integration.slack_view_closed_test.test#closed"
      )
    end
  end

  defmodule TestController do
    def closed(%{pid: pid} = context) do
      send(pid, :called_controller)

      {:ok, context}
    end
  end

  def fixture(:valid_slack_view_closed, callback_id \\ "CALLBACK") do
    view =
      [
        {"callback_id", callback_id}
      ]
      |> Enum.into(%{})

    payload =
      [
        {"type", "view_closed"},
        {"team", %{id: "T1234"}},
        {"user", %{id: "U1234"}},
        {"view", view},
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
      params = fixture(:valid_slack_view_closed, "closed")

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
