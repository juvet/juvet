defmodule Juvet.Connection.SlackRTM.SlackRTMTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Juvet.ProcessHelpers

  alias Juvet.Connection.{SlackRTM}

  setup_all do
    Juvet.FakeSlack.start_link()

    on_exit(fn ->
      Juvet.FakeSlack.stop()
    end)

    {:ok, token: "SLACK_BOT_TOKEN"}
  end

  describe "SlackRTM.connect/2" do
    test "returns a pid", %{token: token} do
      use_cassette "rtm/connect/successful" do
        assert {:ok, _pid} = SlackRTM.connect(self(), %{token: token})
      end
    end

    test "connects to the Slack server", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(self(), %{token: token})

        {:ok, message} = SlackRTM.get_message(pid)

        assert %{url: "ws://localhost:51345/ws"} = message
      end
    end

    test "assigns the latest response to the state", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(self(), %{token: token})

        {:ok, message} = SlackRTM.get_message(pid)

        assert %{team: %{name: "Juvet"}} = message
      end
    end

    test "returns the errors when unsuccessful", %{token: token} do
      use_cassette "rtm/connect/invalid_auth" do
        assert {:error, _} = SlackRTM.connect(self(), %{token: token})
      end
    end
  end

  describe "receiving incoming Slack messages" do
    setup :setup_with_supervised_pubsub!

    test "publishes a connection message when connected", %{token: token} do
      use_cassette "rtm/connect/successful" do
        SlackRTM.connect(self(), %{token: token})
      end

      assert_receive [
        :connected,
        :slack,
        %{ok: true, team: %{name: "Juvet"}}
      ]
    end

    test "publishes a disconnection message when disconnected", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(self(), %{token: token})
        {:ok, message} = SlackRTM.get_message(pid)

        SlackRTM.handle_disconnect(nil, %{
          receiver: self(),
          message: {:ok, message}
        })
      end

      assert_receive [
        :disconnected,
        :slack,
        %{ok: true, team: %{name: "Juvet"}}
      ]
    end

    test "publishes the message to incoming slack message subscribers", %{
      token: token
    } do
      message = Poison.encode!(%{type: "hello"})

      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(self(), %{token: token})

        WebSockex.send_frame(pid, {:text, message})
      end

      assert_receive [:new_message, :slack, ^message]
    end
  end
end
