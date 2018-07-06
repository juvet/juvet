defmodule Juvet.Bot do
  use GenServer

  def start_link(%{team: %{domain: domain}} = initial_message) do
    GenServer.start_link(
      __MODULE__,
      initial_message,
      name: String.to_atom(domain)
    )
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  # Callbacks
  def init(initial_message) do
    ## Subscribe to messages

    PubSub.subscribe(self(), :incoming_slack_message)

    {:ok, initial_message}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_info([:incoming_slack_message, message], state) do
    IO.puts("BOT RECEIVED INFO " <> inspect(message))
    {:noreply, state}
  end
end
