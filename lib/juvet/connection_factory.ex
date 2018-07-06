defmodule Juvet.ConnectionFactory do
  use GenServer

  alias Juvet.ConnectionFactory

  def start_link(supervisor) do
    GenServer.start_link(__MODULE__, [supervisor], name: __MODULE__)
  end

  def connect(platform, arguments) do
    GenServer.call(ConnectionFactory, {:connect, platform, arguments})
  end

  ## Callbacks

  def init([supervisor]) when is_pid(supervisor) do
    init(%{supervisor: supervisor})
  end

  def init(state) do
    send(self(), :start_connection_supervisor)

    {:ok, state}
  end

  def handle_call(
        {:connect, _platform, arguments},
        _from,
        %{connection_supervisor: connection_supervisor} = state
      ) do
    {:ok, pid} =
      Supervisor.start_child(
        connection_supervisor,
        Supervisor.Spec.worker(
          Juvet.Connection.SlackRTM,
          [arguments],
          function: :connect
        )
      )

    {:reply, pid, state}
  end

  def handle_info(
        :start_connection_supervisor,
        %{supervisor: supervisor} = state
      ) do
    {:ok, connection_supervisor} =
      Supervisor.start_child(supervisor, connection_supervisor_spec())

    {:noreply,
     Map.merge(state, %{connection_supervisor: connection_supervisor})}
  end

  defp connection_supervisor_spec() do
    Supervisor.Spec.supervisor(
      Juvet.ConnectionSupervisor,
      [],
      restart: :permanent
    )
  end
end
