defmodule Juvet.Superintendent do
  use GenServer

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
      send(self(), :start_bot_supervisor)
    end

    {:ok, %{config: config}}
  end

  def handle_call(
        {:create_bot, name},
        _from,
        state = %{bot_supervisor: bot_supervisor, config: config}
      ) do
    reply = Juvet.BotSupervisor.add_bot(bot_supervisor, config[:bot], name)

    {:reply, reply, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_cast(
        {:connect_bot, bot, platform, parameters},
        state = %{config: config}
      ) do
    bot_module = Juvet.Config.bot(config)

    bot_module.connect(bot, platform, parameters)

    {:noreply, state}
  end

  def handle_info(:start_bot_supervisor, state) do
    {:ok, bot_supervisor} =
      Supervisor.start_child(
        Juvet.BotFactory,
        Supervisor.child_spec({Juvet.BotSupervisor, [[]]}, restart: :temporary)
      )

    # TODO: Make state a struct and use %{state | bot_supervisor: bot_supervisor}

    {:noreply, Map.merge(state, %{bot_supervisor: bot_supervisor})}
  end
end
