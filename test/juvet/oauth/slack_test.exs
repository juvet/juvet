defmodule Juvet.OAuth.SlackTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.OAuth.Slack

  describe "authorize_url!/1" do
    test "returns the url to request authorization from Slack" do
      assert Slack.authorize_url!() =~
               ~r{https://slack.com/oauth/v2/authorize\?client_id=&redirect_uri=&response_type=code}
    end

    test "returns the url with parameters" do
      assert Slack.authorize_url!(
               client_id: "CLIENT_ID",
               redirect_uri: "REDIRECT_URI",
               scope: "SCOPE"
             ) =~
               ~r{https://slack.com/oauth/v2/authorize\?client_id=CLIENT_ID&redirect_uri=REDIRECT_URI&response_type=code&scope=SCOPE}
    end
  end

  describe "get_token!/1" do
    setup do
      params = [
        client_id: System.get_env("SLACK_CLIENT_ID"),
        client_secret: System.get_env("SLACK_CLIENT_SECRET"),
        code: "CODE"
      ]

      [params: params]
    end

    test "returns the results of the Slack OAuth API call", %{params: params} do
      use_cassette "oauth/v2/access/successful" do
        assert match?(
                 %OAuth2.Client{
                   strategy: Juvet.OAuth.Slack,
                   token: %{
                     access_token: "BOT_TOKEN",
                     other_params: %{
                       "authed_user" => %{},
                       "bot_user_id" => "JUVET",
                       "scope" => "commands,incoming-webhook",
                       "team" => %{}
                     }
                   }
                 },
                 Slack.get_token!(params)
               )
      end
    end

    test "returns the results of a failed Slack OAuth API call", %{params: params} do
      use_cassette "oauth/v2/access/invalid_code" do
        assert match?(
                 %OAuth2.Client{
                   strategy: Juvet.OAuth.Slack,
                   token: %{
                     access_token: nil,
                     other_params: %{
                       "ok" => false,
                       "error" => "invalid_code"
                     }
                   }
                 },
                 Slack.get_token!(params)
               )
      end
    end
  end
end
