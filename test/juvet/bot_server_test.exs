defmodule Juvet.BotServer.BotServerTest do
  use ExUnit.Case, async: true

  alias Juvet.BotServer

  describe "BotServer.start_link\1" do
    defmodule TestBot do
      use Juvet.Bot
    end

    setup do
      message = %{
        ok: true,
        team: %{
          domain: "Led Zeppelin"
        }
      }

      {:ok, bot: TestBot, message: message}
    end

    test "returns a pid", %{bot: bot, message: message} do
      assert {:ok, _pid} = BotServer.start_link({bot, message})
    end

    test "sets the state to the initial message", %{bot: bot, message: message} do
      {:ok, pid} = BotServer.start_link({bot, message})

      assert BotServer.get_state(pid) == {bot, message}
    end

    test "names the process with the Slack domain", %{
      bot: bot,
      message: %{team: %{domain: domain}} = message
    } do
      BotServer.start_link({bot, message})

      assert Process.whereis(String.to_atom(domain)) |> Process.alive?()
    end
  end
end
