defmodule Juvet.BotFactoryTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup_all :setup_reset_config_on_exit

  setup do
    {:ok, config: default_config()}
  end

  describe "Juvet.BotFactory.start_link/1" do
    @tag :skip
    test "starts the superintendent", %{config: config} do
      Juvet.BotFactory.start_link(config)

      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    test "starts the bot supervisor if the configuration is valid", %{
      config: config
    } do
      {:ok, _pid} = Juvet.BotFactory.start_link(config)

      [{id, pid, type, [modules]} | _] =
        Supervisor.which_children(Juvet.BotFactory)

      IO.inspect([modules])

      %{bot_supervisor: supervisor_pid} = Juvet.Superintendent.get_state()

      assert Process.alive?(supervisor_pid)
    end

    @tag :skip
    test "does not start the bot supervisor via the superintendent if the configuration is not valid",
         %{config: config} do
      # Application.put_env(:juvet, :bot, nil)

      Juvet.BotFactory.start_link(config)

      refute Map.has_key?(Juvet.Superintendent.get_state(), :bot_supervisor)
    end
  end

  describe "Juvet.BotFactory.create/2" do
    setup context do
      # TODO: May need to check if it's already started so first test does not fail
      Juvet.BotFactory.start_link(context.config)

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
