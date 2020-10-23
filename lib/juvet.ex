defmodule Juvet do
  use Application

  def start(_types, _args) do
    Juvet.BotFactory.start_link(Application.get_all_env(:juvet))
  end

  def create_bot(name) do
    Juvet.BotFactory.create(name)
  end

  def create_bot!(name) do
    Juvet.BotFactory.create!(name)
  end

  def connect_bot(bot, platform, parameters) do
    Juvet.Superintendent.connect_bot(bot, platform, parameters)
  end

  def start_bot!(name, platform, parameters) do
    bot = __MODULE__.create_bot!(name)
    __MODULE__.connect_bot(bot, platform, parameters)
    bot
  end
end
