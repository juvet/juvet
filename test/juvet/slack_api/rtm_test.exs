defmodule Juvet.SlackAPI.RTM.RTMtest do
  use ExUnit.Case, async: true

  import Mock

  alias Juvet.SlackAPI

  setup do
    {:ok, token: "SLACKBOT_TOKEN"}
  end

  describe "SlackAPI.RTM.connect/1" do
    test "returns the websocket url", %{token: _} = params do
      with_mock SlackAPI.RTM, connect: fn _url -> successful_response() end do
        assert {:ok, %HTTPoison.Response{}} = SlackAPI.RTM.connect(params)
      end
    end
  end

  defp successful_response do
    {:ok, %HTTPoison.Response{}}
  end
end
