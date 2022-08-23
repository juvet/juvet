defmodule Juvet.Receivers.SlackRTMReceiver do
  @moduledoc """
  A receiver that receives messages from a SlackRTM websocket connection.
  """

  use GenServer

  alias Juvet.Connection.SlackRTM

  defmodule State do
    @moduledoc """
    A struct that represents the state that is stored in each connection.
    """

    @type t :: %__MODULE__{
            bot: pid(),
            connection: pid(),
            parameters: map()
          }
    defstruct bot: nil, connection: nil, parameters: %{}
  end

  @doc """
  Starts a child process under the `bot_supervisor` for the specified
  bot `pid` using the specified `parameters`.
  """
  def start(bot_supervisor, bot, %{token: _token} = parameters) do
    Supervisor.start_child(
      bot_supervisor,
      {__MODULE__, [bot, parameters]}
    )
  end

  # Client API

  @doc false
  def start_link([_bot, _parameters] = init_arg, options \\ []) do
    GenServer.start_link(__MODULE__, init_arg, options)
  end

  @doc """
  Returns the process id that represents the websocket connection.
  """
  def get_connection(pid), do: GenServer.call(pid, :get_connection)

  # Server Callbacks

  @doc false
  @impl true
  def init([bot, parameters]) do
    send(self(), :connect_slack_rtm)

    {:ok, %State{bot: bot, parameters: parameters}}
  end

  @doc false
  @impl true
  def handle_call(:get_connection, _from, state) do
    {:reply, state.connection, state}
  end

  @doc false
  @impl true
  def handle_info(
        :connect_slack_rtm,
        %{bot: bot, parameters: parameters} = state
      ) do
    case SlackRTM.connect(bot, parameters) do
      {:ok, pid} ->
        {:noreply, %{state | connection: pid}}

      {:error, _} ->
        raise "Not Implemented"
    end
  end
end
