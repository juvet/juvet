defmodule Juvet.Connection.SlackRTM.SlackRTMTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.Connection.{SlackRTM}

  setup_all do
    Juvet.FakeSlack.start_link()

    on_exit(fn ->
      Juvet.FakeSlack.stop()
    end)

    {:ok, token: "SLACK_BOT_TOKEN"}
  end

  describe "SlackRTM.connect/1" do
    test "returns a pid", %{token: token} do
      use_cassette "rtm/connect/successful" do
        assert {:ok, _pid} = SlackRTM.connect(%{token: token})
      end
    end

    test "connects to the Slack server", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(%{token: token})

        {:ok, state} = SlackRTM.get_state(pid)

        assert %{url: "ws://localhost:51345/ws"} = state
      end
    end

    test "assigns the latest response to the state", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(%{token: token})

        {:ok, state} = SlackRTM.get_state(pid)

        assert %{team: %{name: "Brilliant Fantastic"}} = state
      end
    end

    test "returns the errors when unsuccessful", %{token: token} do
      use_cassette "rtm/connect/invalid_auth" do
        assert {:error, _} = SlackRTM.connect(%{token: token})
      end
    end
  end

  describe "receiving incoming Slack messages" do
    test "publishes a connection message when connected", %{token: token} do
      PubSub.subscribe(self(), :new_slack_connection)

      use_cassette "rtm/connect/successful" do
        SlackRTM.connect(%{token: token})
      end

      assert_receive [
        :new_slack_connection,
        %{ok: true, team: %{name: "Brilliant Fantastic"}}
      ]
    end

    test "publishes a disconnection message when disconnected", %{token: token} do
      PubSub.subscribe(self(), :slack_disconnected)

      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(%{token: token})
        {:ok, state} = SlackRTM.get_state(pid)
        SlackRTM.handle_disconnect(nil, state)
      end

      assert_receive [
        :slack_disconnected,
        %{ok: true, team: %{name: "Brilliant Fantastic"}}
      ]
    end

    test "publishes the message to incoming slack message subscribers" do
      id = "T1234"
      PubSub.subscribe(self(), :"incoming_slack_message_#{id}")
      message = Poison.encode!(%{type: "hello"})

      SlackRTM.handle_frame({:text, message}, %{team: %{id: id}})

      assert_receive [:incoming_slack_message, ^message]
    end
  end

  describe "sending outgoing Slack messages" do
    test "subscribes to outgoing slack messages", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, _pid} = SlackRTM.connect(%{token: token})
        id = "T1234"

        SlackRTM.handle_connect(nil, %{ok: true, team: %{id: id}})

        subscribers = PubSub.subscribers(:"outgoing_slack_message_#{id}")

        assert length(subscribers) == 1
      end
    end
  end
end
