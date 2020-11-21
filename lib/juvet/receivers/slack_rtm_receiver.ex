defmodule Juvet.Receivers.SlackRTMReceiver do
  @moduledoc """
  A receiver that receives messages from a SlackRTM websocket connection.
  """

  use GenServer

  defmodule State do
    defstruct bot: nil, connection: nil, parameters: %{}
  end

  @doc """
  Starts a child process under the `bot_supervisor` for the specified
  bot `pid` using the specified `parameters`.
  """
  def start(bot_supervisor, bot, parameters = %{token: _token}) do
    Supervisor.start_child(
      bot_supervisor,
      {__MODULE__, [bot, parameters]}
    )
  end

  # Client API

  @doc false
  def start_link(init_arg = [_bot, _parameters], options \\ []) do
    GenServer.start_link(__MODULE__, init_arg, options)
  end

  @doc """
  Returns the process id that represents the websocket connection.
  """
  def get_connection(pid), do: GenServer.call(pid, :get_connection)

  # Server Callbacks

  @doc false
  def init([bot, parameters]) do
    send(self(), :connect_slack_rtm)

    {:ok, %State{bot: bot, parameters: parameters}}
  end

  @doc false
  def handle_call(:get_connection, _from, state) do
    {:reply, state.connection, state}
  end

  @doc false
  def handle_info(
        :connect_slack_rtm,
        state = %{bot: bot, parameters: parameters}
      ) do
    # TODO: Call either connect or start based on the `via` parameter in state
    # TODO: Handle an error here

    {:ok, pid} = Juvet.Connection.SlackRTM.connect(bot, parameters)

    {:noreply, %{state | connection: pid}}
  end
end
