defmodule Juvet.Bot.BotTest do
  use ExUnit.Case, async: true

  alias Juvet.Bot

  describe "Bot.start_link\1" do
    setup do
      message = %{
        ok: true,
        team: %{
          domain: "Led Zeppelin"
        }
      }

      {:ok, message: message}
    end

    test "returns a pid", %{message: message} do
      assert {:ok, _pid} = Bot.start_link(message)
    end

    test "sets the state to the initial message", %{message: message} do
      {:ok, pid} = Bot.start_link(message)

      assert Bot.get_state(pid) == message
    end

    test "names the process with the Slack domain", %{
      message: %{team: %{domain: domain}} = message
    } do
      Bot.start_link(message)

      assert Process.whereis(String.to_atom(domain)) |> Process.alive?()
    end
  end
end
