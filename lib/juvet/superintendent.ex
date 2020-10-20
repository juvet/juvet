defmodule Juvet.Superintendent do
  use GenServer

  # Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def create_bot(parameters, options \\ []) do
    GenServer.call(__MODULE__, {:create_bot, parameters, options})
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
        {:create_bot, parameters, options},
        _from,
        state = %{bot_supervisor: bot_supervisor, config: config}
      ) do
    {:ok, bot} =
      DynamicSupervisor.start_child(
        bot_supervisor,
        bot_spec(config[:bot], parameters, options)
      )

    {:reply, bot, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
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

  defp bot_spec(bot, parameters, options) do
    %{
      id: bot,
      start: {bot, :start_link, [parameters, options]}
    }
  end
end
