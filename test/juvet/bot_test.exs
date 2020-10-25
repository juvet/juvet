defmodule Juvet.Bot.BotTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup do
    config = default_config()

    start_supervised!({Juvet.BotFactory, config})

    {:ok, config: config}
  end

  describe "Juvet.Bot.add_receiver/2" do
    setup do
      bot =
        Juvet.start_bot!("Jimmy", :slack, %{
          team_id: "T12345",
          token: "BOT_TOKEN"
        })

      {:ok, bot: bot}
    end

    @tag :skip
    test "creates a child receiver to receive messages from Slack RTM", %{
      bot: bot
    } do
      {:ok, pid} =
        MyBot.add_receiver(bot, :slack_rtm, %{
          via: :start,
          include_locale: true,
          mpim_aware: true
        })

      assert Process.alive?(pid)
    end

    @tag :skip
    test "adds the hello message to the bot's messages", %{bot: bot} do
      MyBot.add_receiver(bot, :slack_rtm, %{
        via: :start,
        include_locale: true,
        mpim_aware: true
      })

      messages = MyBot.get_messages(bot)

      assert List.last(messages).raw_message == %{type: "hello"}
    end
  end
end
