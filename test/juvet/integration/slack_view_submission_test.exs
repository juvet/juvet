defmodule Juvet.Integration.SlackViewSubmissionTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      view_submission("submitted",
        to: "juvet.integration.slack_view_submission_test.test#submit"
      )
    end
  end

  defmodule TestController do
    def submit(%{pid: pid}) do
      send(pid, :called_controller)
    end
  end

  def fixture(:valid_slack_view_submission, callback_id \\ "CALLBACK") do
    view =
      [
        {"callback_id", callback_id}
      ]
      |> Enum.into(%{})

    [
      {"type", "view_submission"},
      {"token", "SLACK_TOKEN"},
      {"team_id", "T1234"},
      {"view", view |> Poison.encode!()}
    ]
    |> Enum.into(%{})
  end

  describe "with a valid Slack command" do
    setup do
      signing_secret = generate_slack_signing_secret()

      [signing_secret: signing_secret]
    end

    test "is routed correctly", %{signing_secret: signing_secret} do
      params = fixture(:valid_slack_view_submission, "submitted")

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
