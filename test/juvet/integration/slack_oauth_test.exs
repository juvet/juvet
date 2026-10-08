defmodule Juvet.Integration.SlackOauthTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Juvet.PlugHelpers

  alias Juvet.OAuth.State

  defmodule MyRouter do
    use Juvet.Router

    platform :slack do
      oauth("error", to: "juvet.integration.slack_oauth_test.test#oauth_error")
      oauth("success", to: "juvet.integration.slack_oauth_test.test#oauth_success")
      oauth("request", to: "juvet.integration.slack_oauth_test.test#oauth_request")
    end
  end

  defmodule TestController do
    def oauth_error(%{pid: pid} = context) do
      send(pid, {:called_error_action, Map.get(context, :error)})

      {:ok, context}
    end

    def oauth_success(%{pid: pid} = context) do
      send(pid, :called_success_action)

      {:ok, context}
    end

    def oauth_request(%{pid: pid, response: %{status: 302}} = context) do
      send(pid, :called_request_action)

      {:ok, context}
    end
  end

  @configuration [
    router: MyRouter,
    slack: [
      oauth_callback_endpoint: "/auth/slack/callback",
      oauth_request_endpoint: "/auth/slack",
      app_id: "APP_ID",
      client_id: "CLIENT_ID",
      client_secret: "CLIENT_SECRET",
      redirect_uri: "REDIRECT_URI",
      scope: "SCOPE",
      user_scope: "USER_SCOPE",
      state_secret: "STATE_SECRET"
    ]
  ]

  describe "with a Slack OAuth request phase" do
    test "it redirects the user to OAuth with Slack" do
      conn = request_phase!()

      assert conn.status == 302
      assert conn.halted
      assert_received :called_request_action

      [location] = Conn.get_resp_header(conn, "location")
      %URI{host: "slack.com", path: "/oauth/v2/authorize", query: query} = URI.parse(location)

      assert %{
               "app_id" => "APP_ID",
               "client_id" => "CLIENT_ID",
               "redirect_uri" => "REDIRECT_URI",
               "response_type" => "code",
               "scope" => "SCOPE",
               "state" => state,
               "user_scope" => "USER_SCOPE"
             } = URI.decode_query(query)

      refute state == ""
      refute location =~ "client_secret"
    end

    test "it stores the state in a signed cookie on the callback path" do
      conn = request_phase!()

      cookie = conn.resp_cookies[State.cookie_name()]
      assert cookie.http_only
      assert cookie.path == "/auth/slack/callback"
      refute cookie.value == state_param(conn)
    end

    test "it does not redirect without a state secret" do
      conn =
        request!(:get, "/auth/slack", %{}, [{"accept", "text/html"}],
          context: %{pid: self()},
          configuration: [
            router: MyRouter,
            slack: Keyword.delete(@configuration[:slack], :state_secret)
          ]
        )

      refute conn.status == 302
      refute_received :called_request_action
    end
  end

  describe "with a Slack OAuth success phase" do
    test "it is routed correctly" do
      use_cassette "oauth/v2/access/successful" do
        conn = callback!(%{"code" => "CODE"}, request_phase!())

        assert conn.status == 200
        assert conn.halted

        assert_received :called_success_action
      end
    end

    test "it clears the state cookie" do
      use_cassette "oauth/v2/access/successful" do
        conn = callback!(%{"code" => "CODE"}, request_phase!())

        assert conn.resp_cookies[State.cookie_name()].max_age == 0
      end
    end
  end

  describe "with a Slack OAuth error phase" do
    test "it is routed correctly" do
      use_cassette "oauth/v2/access/invalid_code" do
        conn = callback!(%{"code" => "INVALID"}, request_phase!())

        assert conn.status == 200
        assert conn.halted

        assert_received {:called_error_action, "invalid_code"}
      end
    end
  end

  describe "with an invalid OAuth state" do
    test "it routes to the error action when the state does not match" do
      request = request_phase!()

      conn =
        request!(
          :get,
          "/auth/slack/callback",
          %{"code" => "CODE", "state" => "FORGED"},
          [{"accept", "text/html"}, {"cookie", state_cookie(request)}],
          context: %{pid: self()},
          configuration: @configuration
        )

      assert conn.halted
      assert conn.resp_cookies[State.cookie_name()].max_age == 0

      assert_received {:called_error_action, :invalid_state}
      refute_received :called_success_action
    end

    test "it routes to the error action when there is no state cookie" do
      conn =
        request!(
          :get,
          "/auth/slack/callback",
          %{"code" => "CODE", "state" => "STATE"},
          [{"accept", "text/html"}],
          context: %{pid: self()},
          configuration: @configuration
        )

      assert conn.halted

      assert_received {:called_error_action, :invalid_state}
      refute_received :called_success_action
    end
  end

  describe "with a Slack OAuth cancel authorization" do
    test "it is routed correctly" do
      conn =
        request!(
          :get,
          "/auth/slack/callback",
          %{"error" => "access_denied", "error_description" => "The user denied your request"},
          [{"accept", "text/html"}],
          context: %{pid: self()},
          configuration: @configuration
        )

      assert conn.status == 200
      assert conn.halted

      assert_received {:called_error_action, "access_denied"}
    end
  end

  defp request_phase! do
    request!(:get, "/auth/slack", %{}, [{"accept", "text/html"}],
      context: %{pid: self()},
      configuration: @configuration
    )
  end

  defp callback!(params, request) do
    request!(
      :get,
      "/auth/slack/callback",
      Map.put(params, "state", state_param(request)),
      [{"accept", "text/html"}, {"cookie", state_cookie(request)}],
      context: %{pid: self()},
      configuration: @configuration
    )
  end

  defp state_cookie(request),
    do: "#{State.cookie_name()}=#{request.resp_cookies[State.cookie_name()].value}"

  defp state_param(request) do
    [location] = Conn.get_resp_header(request, "location")

    location |> URI.parse() |> Map.get(:query) |> URI.decode_query() |> Map.fetch!("state")
  end
end
