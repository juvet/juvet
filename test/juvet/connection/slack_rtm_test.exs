defmodule Juvet.Connection.SlackRTM.SlackRTMTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.Connection.{SlackRTM}

  describe "SlackRTM.start/1" do
    test "returns a pid" do
      use_cassette "rtm/connect/successful" do
        assert {:ok, _pid} = SlackRTM.start(%{token: "SLACK_BOT_TOKEN"})
      end
    end

    test "returns the errors when unsuccessful" do
      use_cassette "rtm/connect/invalid_auth" do
        assert {:error, _} = SlackRTM.start(%{token: "SLACK_BOT_TOKEN"})
      end
    end
  end
end
