defmodule Juvet.SuperintendentTest do
  use ExUnit.Case

  import Juvet.ConfigurationHelpers

  setup do
    {:ok, config: default_config()}
  end

  describe "Juvet.Superintendent.connect_bot/3" do
    test "adds the platform to the bot", %{config: config} do
      start_supervised!({Juvet.BotFactory, config})

      {:ok, bot} = Juvet.BotFactory.create("Jimmy")

      Juvet.Superintendent.connect_bot(bot, :slack, %{team_id: "T12345"})

      :timer.sleep(500)

      %{platforms: platforms} = MyBot.get_state(bot)

      assert List.first(platforms).platform == :slack
      assert List.first(platforms).id == "T12345"
    end
  end
end
