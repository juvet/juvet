defmodule Juvet.Integration.SlackOauthTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney
  use Juvet.PlugHelpers

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
      send(pid, :called_error_action)

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

  describe "with a Slack OAuth request phase" do
    test "it redirects the user to OAuth with Slack" do
      conn =
        request!(
          :get,
          "/auth/slack",
          %{},
          [{"accept", "text/html"}],
          context: %{pid: self()},
          configuration: [
            router: MyRouter,
            slack: [
              oauth_callback_endpoint: "/auth/slack/callback",
              oauth_request_endpoint: "/auth/slack",
              app_id: "APP_ID",
              client_id: "CLIENT_ID",
              client_secret: "CLIENT_SECRET",
              redirect_uri: "REDIRECT_URI",
              scope: "SCOPE",
              user_scope: "USER_SCOPE"
            ]
          ]
        )

      assert conn.status == 302

      assert conn.resp_body ==
               """
               <html><body>You are being <a href=\"https://slack.com/oauth/v2/authorize\?\
               app_id=APP_ID&amp;\
               client_id=CLIENT_ID&amp;\
               client_secret=CLIENT_SECRET&amp;\
               redirect_uri=REDIRECT_URI&amp;\
               response_type=code&amp;\
               scope=SCOPE&amp;\
               user_scope=USER_SCOPE\
               \">redirected</a>.</body></html>\
               """

      assert conn.halted
      assert_received :called_request_action
    end
  end

  describe "with a Slack OAuth success phase" do
    test "it is routed correctly" do
      use_cassette "oauth/v2/access/successful" do
        conn =
          request!(
            :get,
            "/auth/slack/callback",
            %{"code" => "CODE"},
            [{"accept", "text/html"}],
            context: %{pid: self()},
            configuration: [
              router: MyRouter,
              slack: [
                oauth_callback_endpoint: "/auth/slack/callback",
                oauth_request_endpoint: "/auth/slack",
                app_id: "APP_ID",
                client_id: "CLIENT_ID",
                client_secret: "CLIENT_SECRET",
                redirect_uri: "REDIRECT_URI",
                scope: "SCOPE",
                user_scope: "USER_SCOPE"
              ]
            ]
          )

        assert conn.status == 200
        assert conn.halted

        assert_received :called_success_action
      end
    end
  end

  describe "with a Slack OAuth error phase" do
    test "it is routed correctly" do
      use_cassette "oauth/v2/access/invalid_code" do
        conn =
          request!(
            :get,
            "/auth/slack/callback",
            %{"code" => "INVALID"},
            [{"accept", "text/html"}],
            context: %{pid: self()},
            configuration: [
              router: MyRouter,
              slack: [
                oauth_callback_endpoint: "/auth/slack/callback",
                oauth_request_endpoint: "/auth/slack",
                app_id: "APP_ID",
                client_id: "CLIENT_ID",
                client_secret: "CLIENT_SECRET",
                redirect_uri: "REDIRECT_URI",
                scope: "SCOPE",
                user_scope: "USER_SCOPE"
              ]
            ]
          )

        assert conn.status == 200
        assert conn.halted

        assert_received :called_error_action
      end
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
          configuration: [
            router: MyRouter,
            slack: [
              oauth_callback_endpoint: "/auth/slack/callback",
              oauth_request_endpoint: "/auth/slack",
              app_id: "APP_ID",
              client_id: "CLIENT_ID",
              client_secret: "CLIENT_SECRET",
              redirect_uri: "REDIRECT_URI",
              scope: "SCOPE",
              user_scope: "USER_SCOPE"
            ]
          ]
        )

      assert conn.status == 200
      assert conn.halted

      assert_received :called_error_action
    end
  end
end
