defmodule Juvet.Integration.SlackUrlVerificationTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers
  use Juvet.SlackRequestHelpers

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
    end
  end

  def fixture(:slack_url_verification) do
    [
      {"token", "SLACK_TOKEN"},
      {"challenge", "send_this_back"},
      {"type", "url_verification"}
    ]
    |> Enum.into(%{})
  end

  describe "with a valid Slack event" do
    setup do
      signing_secret = generate_slack_signing_secret()

      [signing_secret: signing_secret]
    end

    test "is handled automatically", %{signing_secret: signing_secret} do
      params = fixture(:slack_url_verification)

      conn =
        request!(
          :post,
          "/slack/events",
          params,
          slack_headers(params, signing_secret),
          context: %{},
          configuration: [
            router: MyRouter,
            slack: [signing_secret: signing_secret]
          ]
        )

      assert json_response(conn, 200) == %{"challenge" => params["challenge"]}
      # Request was successful and will not continue in the request chain
      assert conn.halted
    end
  end
end
