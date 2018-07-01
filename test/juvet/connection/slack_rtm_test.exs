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
      Application.put_env(:slack, :test_pid, self())

      use_cassette "rtm/connect/successful" do
        assert {:ok, _pid} = SlackRTM.connect(%{token: token})
      end
    end

    @tag :skip
    test "connects to the Slack server" do
    end

    test "returns the errors when unsuccessful", %{token: token} do
      use_cassette "rtm/connect/invalid_auth" do
        assert {:error, _} = SlackRTM.connect(%{token: token})
      end
    end
  end

  describe "receiving incoming Slack messages" do
    @tag :skip
    test "publishes the message", %{token: token} do
      # Application.put_env(:slack, :test_pid, self())

      use_cassette "rtm/connect/successful" do
        {:ok, pid} = SlackRTM.connect(%{token: token})

        Juvet.FakeSlack.send_message_to_client(pid, %{
          type: :message,
          text: "Hello World"
        })

        # send(server, {:send, {:text, "Hello World"}})
        # send(pid, {:text, Poison.encode!(%{type: "hello"})})
        # send(pid, {:text, "ping"})
      end
    end
  end
end
