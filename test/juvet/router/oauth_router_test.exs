defmodule Juvet.Router.OAuthRouterTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.Router.OAuthRouter

  setup_all do
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

  describe "auth_for/3" do
    test "returns an ok tuple when the authorization is successful", %{
      configuration: configuration
    } do
      use_cassette "oauth/v2/access/successful" do
        assert {:ok, response} = OAuthRouter.auth_for(:slack, configuration, code: "CODE")
        assert %{token: %{access_token: "BOT_TOKEN"}} = response
      end
    end

    test "returns an error tuple when the authotization is not successful", %{
      configuration: configuration
    } do
      use_cassette "oauth/v2/access/invalid_code" do
        assert {:error, "invalid_code", response} =
                 OAuthRouter.auth_for(:slack, configuration, code: "INVALID_CODE")

        assert %{token: %{access_token: nil}} = response
      end
    end
  end

  describe "url_for/4" do
    test "returns the url for the Slack request phase", %{configuration: configuration} do
      assert OAuthRouter.url_for(:slack, :request, configuration) =~
               ~r{https://slack.com/oauth/v2/authorize\?app_id=APP_ID&client_id=CLIENT_ID&client_secret=CLIENT_SECRET&redirect_uri=juvetio&response_type=code&scope=commands&user_scope=identity}
    end

    test "returns nil for a request it does not support", %{configuration: configuration} do
      refute OAuthRouter.url_for(:unknown, :request, configuration)
    end
  end
end
