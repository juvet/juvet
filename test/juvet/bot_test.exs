defmodule Juvet.Bot.BotTest do
  use ExUnit.Case

  import Juvet.ProcessHelpers

  defmodule TestBot do
    use Juvet.Bot
  end

  describe "Bot.send_message/1" do
    setup :setup_with_supervised_application!

    test "publishes a message to an outgoing platform" do
      id = "T1234"
      PubSub.subscribe(self(), :"outgoing_slack_message_#{id}")

      TestBot.send_message(:slack, %{id: id}, %{
        type: :message,
        text: "Hello world"
      })

      assert_receive [
        :outgoing_slack_message,
        %{type: :message, text: "Hello world"}
      ]
    end
  end
end
