defmodule Juvet.Bot do
  use GenServer

  def start_link(options \\ %{}) do
    GenServer.start_link(__MODULE__, options)
  end

  # Server
  def init(args) do
    ## Subscribe to messages
    PubSub.subscribe(self(), :incoming_slack_message)

    {:ok, args}
  end

  def handle_info(message, state) do
    IO.puts("RECEIVED INFO " <> inspect(message))
    {:noreply, state}
  end
end
