defmodule Juvet.Connection.SlackRTM.SlackRTMTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.Connection.{SlackRTM}

  setup_all do
    Juvet.FakeSlack.start_link()

    on_exit(fn ->
      Juvet.FakeSlack.stop()
    end)
  end

  describe "SlackRTM.start/1" do
    setup do
      {:ok, token: "SLACK_BOT_TOKEN"}
    end

    test "returns a pid", %{token: token} do
      Application.put_env(:slack, :test_pid, self())

      use_cassette "rtm/connect/successful" do
        assert {:ok, _pid} = SlackRTM.start(%{token: token})
      end
    end

    test "returns the errors when unsuccessful", %{token: token} do
      Application.put_env(:slack, :test_pid, self())

      use_cassette "rtm/connect/invalid_auth" do
        assert {:error, _} = SlackRTM.start(%{token: token})
      end
    end
  end
end
