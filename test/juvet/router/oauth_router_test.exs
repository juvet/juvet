defmodule Juvet.Router.OAuthRouterTest do
  use ExUnit.Case, async: true

  alias Juvet.Router.OAuthRouter

  describe "url_for/4" do
    setup do
      configuration = [
        slack: [
          app_id: "APP_ID",
          client_id: "CLIENT_ID",
          client_secret: "CLIENT_SECRET",
          redirect_uri: "juvetio",
          scope: "commands",
          user_scope: "identity"
        ]
      ]

      [configuration: configuration]
    end

    test "returns the url for the Slack request phase", %{configuration: configuration} do
      assert OAuthRouter.url_for(:slack, :request, configuration) =~
               ~r{https://slack.com/oauth/v2/authorize\?app_id=APP_ID&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&redirect_uri=juvetio&response_type=code&scope=commands&user_scope=identity}
    end

    test "returns nil for a request it does not support", %{configuration: configuration} do
      refute OAuthRouter.url_for(:unknown, :request, configuration)
    end
  end
end
