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

    test "adds the hello message to the bot's messages", %{bot: bot} do
      use_cassette "rtm/connect/successful" do
        {:ok, pid} =
          MyBot.add_receiver(bot, :slack_rtm, %{
            via: :start,
            token: "MY TOKEN",
            include_locale: true,
            mpim_aware: true
          })

        client = Juvet.Receivers.SlackRTMReceiver.get_connection(pid)

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
        credentials: %{
          other: %{
            team_id: "T1234",
            team: "Zeppelin",
            team_url: "https://zeppelin.slack.com"
          },
          token: "SLACK_TOKEN",
          scopes: ["identify"]
        },
        extra: %{
          raw_info: %{
            user: %{
              id: "U12345"
            }
          }
        },
        info: %{
          name: "Jimmy Page",
          nickname: "jimmy"
        }
      }

      {:ok, bot: bot, auth: auth}
    end

    test "returns the user if successful", %{
      bot: bot,
      auth: auth
    } do
      {:ok, user, _team} = MyBot.user_install(bot, :slack, auth)

      assert user.id == "U12345"
      assert user.name == "Jimmy Page"
    end

    test "returns the team if successful", %{
      bot: bot,
      auth: auth
    } do
      {:ok, _user, team} = MyBot.user_install(bot, :slack, auth)

      assert team.id == "T1234"
      assert team.name == "Zeppelin"
    end

    test "adds the platform to the bot's state", %{bot: bot, auth: auth} do
      MyBot.user_install(bot, :slack, auth)

      assert %Juvet.BotState{
               platforms: [%Juvet.BotState.Platform{name: :slack}]
             } = MyBot.get_state(bot)
    end

    test "adds the team to the bot's state if it's not yet there", %{
      bot: bot,
      auth: auth
    } do
      MyBot.user_install(bot, :slack, auth)

      assert %Juvet.BotState{
               platforms: [
                 %Juvet.BotState.Platform{
                   name: :slack,
                   teams: [
                     %Juvet.BotState.Team{
                       id: "T1234",
                       name: "Zeppelin",
                       url: "https://zeppelin.slack.com",
                       token: "SLACK_TOKEN",
                       scopes: ["identify"]
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

      assert %Juvet.BotState{
               platforms: [
                 %Juvet.BotState.Platform{
                   name: :slack,
                   teams: [
                     %Juvet.BotState.Team{
                       id: "T1234",
                       users: [
                         %Juvet.BotState.User{
                           id: "U12345",
                           username: "jimmy",
                           name: "Jimmy Page",
                           token: "SLACK_TOKEN",
                           scopes: ["identify"]
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
