defmodule Juvet.BotFactoryTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup_all :setup_reset_config_on_exit

  setup do
    {:ok, config: default_config()}
  end

  describe "Juvet.BotFactory.start_link/1" do
    test "starts the superintendent", %{config: config} do
      start_supervised!({Juvet.BotFactory, config})

      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    test "starts the bot supervisor if the configuration is valid", %{
      config: config
    } do
      start_supervised!({Juvet.BotFactory, config})

      %{bot_supervisor: supervisor_pid} = Juvet.Superintendent.get_state()

      assert Process.alive?(supervisor_pid)
    end

    test "does not start the bot supervisor via the superintendent if the configuration is not valid",
         %{config: config} do
      start_supervised!({Juvet.BotFactory, Keyword.merge(config, bot: nil)})

      refute Map.has_key?(Juvet.Superintendent.get_state(), :bot_supervisor)
    end
  end

  describe "Juvet.BotFactory.create/2" do
    setup context do
      start_supervised!({Juvet.BotFactory, context.config})

      :ok
    end

    @tag :skip
    test "starts a new process for a bot" do
      {:ok, bot} =
        Juvet.BotFactory.create(
          [slack: %{team_id: "T12345"}],
          name: "Jamie's Bot"
        )

      assert Process.alive?(bot)
    end
  end
end
