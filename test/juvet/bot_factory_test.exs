defmodule Juvet.BotFactoryTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup do
    {:ok, config: default_config()}
  end

  describe "Juvet.BotFactory.start_link/1" do
    test "starts the superintendent", %{config: config} do
      start_supervised!({Juvet.BotFactory, config})

      assert Process.whereis(Juvet.Superintendent) |> Process.alive?()
    end

    test "starts the factory supervisor if the configuration is valid", %{
      config: config
    } do
      start_supervised!({Juvet.BotFactory, config})

      %{factory_supervisor: supervisor_pid} = Juvet.Superintendent.get_state()

      assert Process.alive?(supervisor_pid)
    end

    test "does not start the factory supervisor via the superintendent if the configuration is not valid",
         %{config: config} do
      start_supervised!({Juvet.BotFactory, Keyword.merge(config, bot: nil)})

      refute Juvet.Superintendent.get_state().factory_supervisor
    end
  end

  describe "Juvet.BotFactory.create/1" do
    setup context do
      start_supervised!({Juvet.BotFactory, context.config})

      :ok
    end

    test "starts a new process for a bot" do
      {:ok, bot} = Juvet.BotFactory.create("Jamie's Bot")

      assert Process.alive?(bot)

      assert String.to_atom("Jamie's Bot")
             |> Process.whereis()
             |> Process.alive?()
    end
  end

  describe "Juvet.BotFactory.find/1" do
    setup context do
      start_supervised!({Juvet.BotFactory, context.config})

      bot_name = "My Bot"
      Juvet.BotFactory.create(bot_name)

      [bot_name: bot_name]
    end

    test "returns the process for a bot in a response tuple", %{
      bot_name: bot_name
    } do
      {:ok, bot} = Juvet.BotFactory.find(bot_name)

      assert Process.alive?(bot)
    end

    test "returns error if the bot does not exist" do
      assert {:error, "Bot named 'blah' not found"} =
               Juvet.BotFactory.find("blah")
    end
  end

  describe "Juvet.BotFactory.find!/1" do
    setup context do
      start_supervised!({Juvet.BotFactory, context.config})

      bot_name = "My Bot"
      Juvet.BotFactory.create(bot_name)

      [bot_name: bot_name]
    end

    test "returns just the pid for a bot", %{bot_name: bot_name} do
      bot = Juvet.BotFactory.find!(bot_name)

      assert Process.alive?(bot)
    end

    test "raises an error if the bot is not found" do
      assert_raise RuntimeError, fn ->
        Juvet.BotFactory.find!("Jamie's Bot")
      end
    end
  end

  describe "Juvet.BotFactory.create!/1" do
    setup context do
      start_supervised!({Juvet.BotFactory, context.config})

      :ok
    end

    test "starts a new process for a bot and returns just the pid" do
      bot = Juvet.BotFactory.create!("Jamie's Bot")

      assert Process.alive?(bot)

      assert String.to_atom("Jamie's Bot")
             |> Process.whereis()
             |> Process.alive?()
    end

    test "raises an error if the bot is already created" do
      Juvet.BotFactory.create!("Jamie's Bot")

      assert_raise RuntimeError, fn ->
        Juvet.BotFactory.create!("Jamie's Bot")
      end
    end
  end
end
