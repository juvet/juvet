defmodule Juvet.SlackAPI.RTM.RTMtest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, token: "TOKEN"}
  end

  describe "SlackAPI.RTM.connect/1" do
    test "returns the websocket url", %{token: token} do
      use_cassette "rtm/connect/successful" do
        assert {:ok, %{} = response} = SlackAPI.RTM.connect(%{token: token})
        assert response[:url]
      end
    end
  end
end
