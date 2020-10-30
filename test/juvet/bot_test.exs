defmodule Juvet.Bot.BotTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Juvet.ConfigurationHelpers

  setup_all do
    Juvet.FakeSlack.start_link()

    on_exit(fn ->
      Juvet.FakeSlack.stop()
    end)
  end

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

    test "creates a child receiver to receive messages from Slack RTM", %{
      bot: bot
    } do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} =
          MyBot.add_receiver(bot, :slack_rtm, %{
            via: :start,
            token: "MY TOKEN",
            include_locale: true,
            mpim_aware: true
          })

        assert Process.alive?(pid)
      end
    end

    @tag :skip
    test "adds the hello message to the bot's messages", %{bot: bot} do
      MyBot.add_receiver(bot, :slack_rtm, %{
        via: :start,
        token: "MY TOKEN",
        include_locale: true,
        mpim_aware: true
      })

      messages = MyBot.get_messages(bot)

      assert List.last(messages).raw_message == %{type: "hello"}
    end

    @tag :skip
    test "without a token parameter returns an error" do
    end
  end
end
