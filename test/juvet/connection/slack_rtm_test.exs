defmodule Juvet.Connection.SlackRTM.SlackRTMTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.Connection.{SlackRTM}

  setup_all do
    {:ok, server} = Juvet.FakeSlack.start_link()

    on_exit(fn ->
      Juvet.FakeSlack.stop()
    end)

    {:ok, server: server}
  end

  setup context do
    {:ok, token: "SLACK_BOT_TOKEN", server: context.server}
  end

  describe "SlackRTM.connect/1" do
    test "returns a pid", %{token: token} do
      use_cassette "rtm/connect/successful" do
        assert {:ok, _pid} = SlackRTM.connect(%{token: token})
      end
    end

    test "connects to the Slack server", %{token: token, server: server} do
      Juvet.FakeSlack.set_client_pid(self())

      use_cassette "rtm/connect/successful" do
        SlackRTM.connect(%{token: token})
      end

      assert_received {:websocket_connected, server}
    end

    test "assigns the latest response to the state", %{token: token} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(%{token: token})

        {:ok, state} = SlackRTM.get_state(pid)

        assert state = %{self: %{name: "Brilliant Fantastic"}}
      end
    end

    test "returns the errors when unsuccessful", %{token: token} do
      use_cassette "rtm/connect/invalid_auth" do
        assert {:error, _} = SlackRTM.connect(%{token: token})
      end
    end
  end

  describe "receiving incoming Slack messages" do
    setup do
      {:ok, pub_sub} = PubSub.start_link()

      on_exit(fn ->
        PubSub.terminate(pub_sub, :shutdown)
      end)
    end

    test "publishes the message to incoming slack message subscribers" do
      PubSub.subscribe(self(), :incoming_slack_message)
      message = Poison.encode!(%{type: "hello"})

      SlackRTM.handle_frame({:text, message}, %{})

      assert_receive message
    end
  end
end
