defmodule Juvet.JuvetTest do
  use ExUnit.Case, async: true

  describe "Juvet.start/2" do
    test "starts the pub sub process" do
      assert Process.whereis(PubSub) |> Process.alive?()
    end

    test "starts the bot factory supervisor" do
      assert Process.whereis(Juvet.BotFactorySupervisor) |> Process.alive?()
    end

    test "starts the bot shop" do
      assert Process.whereis(Juvet.BotShop) |> Process.alive?()
    end
  end
end
