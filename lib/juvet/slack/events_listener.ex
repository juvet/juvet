defmodule Juvet.Slack.EventsListener do
  use GenServer

  # Client API

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  # Server Callbacks

  def init(state) do
    {:ok, state}
  end
end
