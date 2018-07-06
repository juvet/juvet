defmodule Juvet.Bot do
  use GenServer

  @moduledoc """
  A behavior module for implementing a bot.

  A bot can be targeted for one or many platforms. The main function
  to implement is the `handle_message` function which will fire for
  any incoming message to the bot. The `send` function will send any
  message back to the server.
  """

  @doc ~S"""
  Starts a new bot process for Slack.

  Returns `{:ok, pid}` where `pid` is the process id of this bot.

  ## Example

  {:ok, pid} = Juvet.Bot.start_link(initial_message)
  """
  def start_link(%{team: %{domain: domain}} = initial_message) do
    GenServer.start_link(
      __MODULE__,
      initial_message,
      name: String.to_atom(domain)
    )
  end

  @doc ~S"""
  Returns the current state of the Slack process.

  ## Example

  {:ok, pid} = Juvet.Bot.start_link(initial_message)
  message = Juvet.Bot.get_state(pid)
  """
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  ## Callbacks

  @doc false
  def init(initial_message) do
    ## Subscribe to messages
    PubSub.subscribe(self(), :incoming_slack_message)

    {:ok, initial_message}
  end

  @doc false
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def handle_info([:incoming_slack_message, message], state) do
    IO.puts("BOT RECEIVED INFO " <> inspect(message))
    {:noreply, state}
  end
end
