defmodule Juvet do
  use Application

  def start(_types, _args) do
    Juvet.BotFactory.start_link(Application.get_all_env(:juvet))
  end
end
