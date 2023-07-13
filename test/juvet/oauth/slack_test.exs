defmodule Juvet.OAuth.SlackTest do
  use ExUnit.Case, async: true

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
end
