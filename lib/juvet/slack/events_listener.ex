defmodule Juvet.Slack.EventsListener do
  use GenServer

  # Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  # Server Callbacks

  def init(config) do
    {:ok, %{config: config}}
  end
end
