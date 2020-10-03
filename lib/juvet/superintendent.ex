defmodule Juvet.Superintendent do
  use GenServer

  # Client API

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Server Callbacks

  def init(:ok) do
    # TODO: Ensure the configuration is specified correct

    send(self(), :start_bot_supervisor)

    {:ok, %{}}
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
