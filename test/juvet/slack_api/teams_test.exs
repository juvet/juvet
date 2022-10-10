defmodule Juvet.SlackAPI.TeamsTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, team: "TEAM1", token: "TOKEN"}
  end

  describe "SlackAPI.Teams.info/1" do
    test "returns infomation about the team", %{team: team, token: token} do
      use_cassette "team/info/successful" do
        assert {:ok, %{} = response} = SlackAPI.Teams.info(%{team: team, token: token})

        assert response[:team][:id]
      end
    end

    test "returns an error from an unsuccessful API call", %{
      team: team,
      token: token
    } do
      use_cassette "team/info/invalid_auth" do
        assert {:error, %{} = response} = SlackAPI.Teams.info(%{team: team, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end
end
