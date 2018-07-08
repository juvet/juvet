defmodule Juvet.BotFactory do
  use GenServer

  @moduledoc """
  A Module for instructing a supervisor on adding and removing bot
  processes.
  """

  alias Juvet.BotFactory

  @doc ~S"""
  Starts a new process for managing bots in an application.

  Upon initialization, this adds this bot factory as a child process to
  a bot supervisor. In addition, another supervisor is created as a
  sibling to this bot factory work process which supervises all of the
  bots that are added through this factory.

  Returns `{:ok, pid}` where `pid` is the process id of this factory.

  ## Example

  {:ok, pid} = Juvet.BotFactory.start_link(supervisor_pid, [%{bot: MyBot}])
  """
  def start_link(supervisor, config) do
    GenServer.start_link(__MODULE__, [supervisor, config], name: __MODULE__)
  end

  @doc ~S"""
  Adds a new bot process to the bot supervisor with the `message` as an
  argument.

  Returns `:ok`.

  ## Example

  :ok = Juvet.BotFactory.add_bot(%{team: %{domain: "Led Zeppelin"}})
  """
  def add_bot(message) do
    GenServer.cast(BotFactory, {:add_bot, message})
  end

  ## Callbacks

  @doc false
  def init([supervisor, config]) when is_pid(supervisor) do
    init(config, %{supervisor: supervisor})
  end

  @doc false
  def init(config, state) do
    PubSub.subscribe(self(), :new_slack_connection)

    send(self(), :start_bot_supervisor)

    {:ok, Map.merge(%{config: config}, state)}
  end

  @doc false
  def handle_cast(
        {:add_bot, message},
        %{bot_supervisor: bot_supervisor, config: config} = state
      ) do
    DynamicSupervisor.start_child(
      bot_supervisor,
      {Juvet.BotServer, {config[:bot], message}}
    )

    {:noreply, state}
  end

  @doc false
  def handle_info(:start_bot_supervisor, %{supervisor: supervisor} = state) do
    {:ok, bot_supervisor} =
      Supervisor.start_child(supervisor, bot_supervisor_spec())

    {:noreply, Map.merge(state, %{bot_supervisor: bot_supervisor})}
  end

  @doc false
  def handle_info([:new_slack_connection, %{ok: true} = message], state) do
    BotFactory.add_bot(message)

    {:noreply, state}
  end

  @doc false
  defp bot_supervisor_spec() do
    Supervisor.Spec.supervisor(
      Juvet.BotSupervisor,
      [],
      restart: :permanent
    )
  end
end
