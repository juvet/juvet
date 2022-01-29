defmodule Juvet.Bot.BotTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  import Juvet.ConfigurationHelpers

  alias Juvet.BotState
  alias Juvet.BotState.{Platform, Team, User}
  alias Juvet.Receivers.SlackRTMReceiver

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

    test "adds the hello message to the bot's messages", %{bot: bot} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} =
          MyBot.add_receiver(bot, :slack_rtm, %{
            via: :start,
            token: "MY TOKEN",
            include_locale: true,
            mpim_aware: true
          })

        client = SlackRTMReceiver.get_connection(pid)

        message = Poison.encode!(%{type: "hello"})
        WebSockex.send_frame(client, {:text, message})

        :timer.sleep(500)

        messages = MyBot.get_messages(bot)

        assert List.last(messages) == message
      end
    end

    @tag :skip
    test "without a token parameter returns an error" do
    end
  end

  describe "Juvet.Bot.user_install/3" do
    setup do
      bot = Juvet.create_bot!("Jimmy")

      auth = %{
        access_token: "BOT_TOKEN",
        authed_user: %{
          id: "U12345",
          access_token: "USER_TOKEN",
          scope: "identify"
        },
        bot_user_id: "UBOT",
        scope: "users:read,team:read",
        team: %{id: "T1234", name: "Zeppelin"},
        token_type: "bot"
      }

      {:ok, bot: bot, auth: auth}
    end

    test "returns the user if successful", %{
      bot: bot,
      auth: auth
    } do
      {:ok, user, _team} = MyBot.user_install(bot, :slack, auth)

      assert user.id == "U12345"
      assert user.token == "USER_TOKEN"
      assert user.scopes == "identify"
    end

    test "returns the team if successful", %{
      bot: bot,
      auth: auth
    } do
      {:ok, _user, team} = MyBot.user_install(bot, :slack, auth)

      assert team.id == "T1234"
      assert team.name == "Zeppelin"
      assert team.scopes == "users:read,team:read"
    end

    test "adds the platform to the bot's state", %{bot: bot, auth: auth} do
      MyBot.user_install(bot, :slack, auth)

      assert %BotState{
               platforms: [%Platform{name: :slack}]
             } = MyBot.get_state(bot)
    end

    test "adds the team to the bot's state if it's not yet there", %{
      bot: bot,
      auth: auth
    } do
      MyBot.user_install(bot, :slack, auth)

      assert %BotState{
               platforms: [
                 %Platform{
                   name: :slack,
                   teams: [
                     %Team{
                       id: "T1234",
                       name: "Zeppelin",
                       token: "BOT_TOKEN",
                       scopes: "users:read,team:read"
                     }
                   ]
                 }
               ]
             } = MyBot.get_state(bot)
    end

    test "adds the user to the bot's state if it's not yet there", %{
      bot: bot,
      auth: auth
    } do
      MyBot.user_install(bot, :slack, auth)

      assert %BotState{
               platforms: [
                 %Platform{
                   name: :slack,
                   teams: [
                     %Team{
                       id: "T1234",
                       users: [
                         %User{
                           id: "U12345",
                           token: "USER_TOKEN",
                           scopes: "identify"
                         }
                       ]
                     }
                   ]
                 }
               ]
             } = MyBot.get_state(bot)
    end
  end
end
