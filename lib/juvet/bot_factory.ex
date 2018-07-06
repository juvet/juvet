defmodule Juvet.BotFactory do
  use GenServer

  alias Juvet.BotFactory

  def start_link(supervisor, config) do
    GenServer.start_link(__MODULE__, [supervisor, config], name: __MODULE__)
  end

  def add_bot(message) do
    GenServer.cast(BotFactory, {:add_bot, message})
  end

  # Callbacks
  def init([supervisor, config]) when is_pid(supervisor) do
    init(config, %{supervisor: supervisor})
  end

  def init(_config, state) do
    PubSub.subscribe(self(), :new_slack_connection)

    send(self(), :start_bot_supervisor)

    {:ok, state}
  end

  def handle_cast(
        {:add_bot, message},
        %{bot_supervisor: bot_supervisor} = state
      ) do
    Supervisor.start_child(
      bot_supervisor,
      Supervisor.Spec.worker(Juvet.Bot, [message])
    )

    {:noreply, state}
  end

  def handle_info(:start_bot_supervisor, %{supervisor: supervisor} = state) do
    {:ok, bot_supervisor} =
      Supervisor.start_child(supervisor, bot_supervisor_spec())

    {:noreply, Map.merge(state, %{bot_supervisor: bot_supervisor})}
  end

  # Handle when a new bot is created...
  def handle_info(%{ok: true} = message, state) do
    BotFactory.add_bot(message)

    {:noreply, state}
  end

  defp bot_supervisor_spec() do
    Supervisor.Spec.supervisor(
      Juvet.BotSupervisor,
      [],
      restart: :permanent
    )
  end
end
