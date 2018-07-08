defmodule Juvet.BotServer do
  use GenServer

  @moduledoc """
  A server that receives messages and holds the state for a bot.

  A bot can be targeted for one or many platforms. The main function
  to send messages to bot macros and hold onto the state of a bot.
  """

  @doc ~S"""
  Starts a new bot process for Slack.

  Returns `{:ok, pid}` where `pid` is the process id of this bot.

  ## Example

  {:ok, pid} = Juvet.BotServer.start_link({MyBot, initial_message})
  """
  def start_link({bot, %{team: %{domain: domain}} = initial_message}) do
    GenServer.start_link(
      __MODULE__,
      [bot, initial_message],
      name: String.to_atom(domain)
    )
  end

  @doc ~S"""
  Returns the current state of the Slack process.

  ## Example

  {:ok, pid} = Juvet.BotServer.start_link(MyBot, initial_message)
  message = Juvet.BotServer.get_state(pid)
  """
  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  ## Callbacks

  @doc false
  def init([bot, %{team: %{id: id}} = initial_message]) do
    # Subscribe to messages
    PubSub.subscribe(self(), :"incoming_slack_message_#{id}")

    bot_state = %{messages: [initial_message]}
    if bot, do: bot.handle_connect(:slack, bot_state)

    {:ok, Map.merge(%{bot: bot}, bot_state)}
  end

  @doc false
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @doc false
  def handle_info([:incoming_slack_message, message], %{bot: bot} = state) do
    if bot, do: bot.handle_event(:slack, message, Map.drop(state, [:bot]))
    {:noreply, state}
  end
end
