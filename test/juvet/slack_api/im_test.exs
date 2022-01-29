defmodule Juvet.SlackAPI.IM.IMtest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, user: "USER1", token: "TOKEN"}
  end

  describe "SlackAPI.IM.open/1" do
    test "returns the channel id", %{user: user, token: token} do
      use_cassette "im/open/successful" do
        assert {:ok, %{} = response} = SlackAPI.IM.open(%{user: user, token: token})

        assert response[:channel][:id]
      end
    end

    test "returns an error from an unsuccessful API call", %{
      user: user,
      token: token
    } do
      use_cassette "im/open/invalid_auth" do
        assert {:error, %{} = response} = SlackAPI.IM.open(%{user: user, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end
end
