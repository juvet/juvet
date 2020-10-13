defmodule Juvet.BotFactoryTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup_all :setup_reset_config_on_exit

  describe "Juvet.BotFactory.start_link\0" do
    test "starts the superintendent" do
      Juvet.BotFactory.start_link()

      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    test "starts the bot supervisor via the superintendent if the configuration is valid" do
      Application.put_env(:juvet, :bot, MyBot)

      Juvet.BotFactory.start_link()

      %{bot_supervisor: supervisor_pid} = Juvet.Superintendent.get_state()

      assert Process.alive?(supervisor_pid)
    end

    test "does not start the bot supervisor via the superintendent if the configuration is not valid" do
      Application.put_env(:juvet, :bot, nil)

      Juvet.BotFactory.start_link()

      refute Map.has_key?(Juvet.Superintendent.get_state(), :bot_supervisor)
    end
  end
end
