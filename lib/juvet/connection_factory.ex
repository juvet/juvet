defmodule Juvet.ConnectionFactory do
  use GenServer

  @moduledoc """
  A Module for instructing a supervisor on adding and removing
  connections to third party bot services.
  """

  alias Juvet.ConnectionFactory

  @doc ~S"""
  Starts a new process for connecting bots in an application.

  Upon initialization, this adds this connection factory as a child
  process to a connection supervisor. In addition, another supervisor
  is created as a sibling to this connection factory work process which
  supervises all of the connections that are added through this factory.

  Returns `{:ok, pid}` where `pid` is the process id of this factory.

  ## Example

  {:ok, pid} = Juvet.ConnectionFactory.start_link(supervisor_pid)
  """
  def start_link(supervisor) do
    GenServer.start_link(__MODULE__, [supervisor], name: __MODULE__)
  end

  @doc ~S"""
  Adds a new connection process to the connection supervisor with the
  `arguments` needed to connect to that `platform`.

  Returns `pid` which is the process id of the connection.

  ## Example

  :ok = Juvet.ConnectionFactory.connect(:slack, %{token: token})
  """
  def connect(platform, arguments) do
    GenServer.call(ConnectionFactory, {:connect, platform, arguments})
  end

  ## Callbacks

  @doc false
  def init([supervisor]) when is_pid(supervisor) do
    init(%{supervisor: supervisor})
  end

  @doc false
  def init(state) do
    send(self(), :start_connection_supervisor)

    {:ok, state}
  end

  @doc false
  def handle_call(
        {:connect, _platform, arguments},
        _from,
        %{connection_supervisor: connection_supervisor} = state
      ) do
    {:ok, pid} =
      DynamicSupervisor.start_child(
        connection_supervisor,
        Supervisor.Spec.worker(
          Juvet.Connection.SlackRTM,
          [arguments],
          function: :connect
        )
      )

    {:reply, pid, state}
  end

  @doc false
  def handle_info(
        :start_connection_supervisor,
        %{supervisor: supervisor} = state
      ) do
    {:ok, connection_supervisor} =
      Supervisor.start_child(supervisor, connection_supervisor_spec())

    {:noreply,
     Map.merge(state, %{connection_supervisor: connection_supervisor})}
  end

  @doc false
  defp connection_supervisor_spec() do
    Supervisor.Spec.supervisor(
      Juvet.ConnectionSupervisor,
      [],
      restart: :permanent
    )
  end
end
