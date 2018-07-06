defmodule Juvet.BotFactorySupervisor.BotFactorySupervisorTest do
  use ExUnit.Case, async: true

  alias Juvet.{BotFactorySupervisor, BotFactory}

  describe "BotFactorySupervisor.start_link\0" do
    test "starts the bot factory" do
      BotFactorySupervisor.start_link()

      assert Process.whereis(BotFactory) |> Process.alive?()
    end
  end
end
