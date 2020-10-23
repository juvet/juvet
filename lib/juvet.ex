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

  # bot could be a pid, converted id, or a name
  def connect_bot(bot, platform, parameters) do
  end

  def connect_bot!(bot, platform, parameters) do
  end

  # def start_bot(name, platform, parameters) -> creates and connects the bot

  # TODO: In Juvet.Bot, add def connect(platform, parameters)
  # -> Adds a GenServer to the bot (in this case, it is a SlackRTM connection)
end
