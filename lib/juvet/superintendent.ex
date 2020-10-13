defmodule Juvet.Superintendent do
  use GenServer

  # Client API

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def get_state, do: GenServer.call(__MODULE__, :get_state)

  # Server Callbacks

  def init(:ok) do
    if Juvet.Config.valid?() do
      send(self(), :start_bot_supervisor)
    end

    {:ok, %{}}
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
end
