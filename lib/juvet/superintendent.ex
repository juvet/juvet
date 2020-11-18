defmodule Juvet.Superintendent do
  use GenServer

  defmodule State do
    defstruct factory_supervisor: nil, config: %{}
  end

  # Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def connect_bot(bot, :slack, parameters = %{team_id: _team_id}) do
    GenServer.cast(__MODULE__, {:connect_bot, bot, :slack, parameters})
  end

  def create_bot(name) do
    GenServer.call(__MODULE__, {:create_bot, name})
  end

  def get_state, do: GenServer.call(__MODULE__, :get_state)

  # Server Callbacks

  def init(config) do
    if Juvet.Config.valid?(config) do
      send(self(), :start_endpoint)
      send(self(), :start_factory_supervisor)
    end

    {:ok, %State{config: config}}
  end

  def handle_call(
        {:create_bot, name},
        _from,
        state = %{factory_supervisor: factory_supervisor, config: config}
      ) do
    reply =
      Juvet.FactorySupervisor.add_bot(factory_supervisor, config[:bot], name)

    {:reply, reply, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, Map.from_struct(state)}
  end

  def handle_cast(
        {:connect_bot, bot, platform, parameters},
        state = %{config: config}
      ) do
    bot_module = Juvet.Config.bot(config)

    bot_module.connect(bot, platform, parameters)

    {:noreply, state}
  end

  def handle_info(:start_factory_supervisor, state) do
    {:ok, factory_supervisor} =
      Supervisor.start_child(
        Juvet.BotFactory,
        Supervisor.child_spec({Juvet.FactorySupervisor, [[]]},
          restart: :temporary
        )
      )

    {:noreply, %{state | factory_supervisor: factory_supervisor}}
  end

  def handle_info(:start_endpoint, state = %{config: config}) do
    {:ok, _endpoint} =
      Supervisor.start_child(
        Juvet.BotFactory,
        Supervisor.child_spec({Juvet.Endpoint, [config]},
          restart: :permanent
        )
      )

    {:noreply, state}
  end
end
