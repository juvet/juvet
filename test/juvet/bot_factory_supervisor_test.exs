defmodule Juvet.BotFactorySupervisor.BotFactorySupervisorTest do
  use ExUnit.Case, async: true

  alias Juvet.{BotFactorySupervisor, BotFactory}

  describe "BotFactorySupervisor.start_link\0" do
    test "starts the bot factory with the specified config" do
      BotFactorySupervisor.start_link([%{bot: nil}])

      assert Process.whereis(BotFactory) |> Process.alive?()
    end
  end
end
