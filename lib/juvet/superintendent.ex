defmodule Juvet.Superintendent do
  @moduledoc """
  Process that acts as the brains around processes within Juvet.

  It starts the `Juvet.BotFactory` process only if the configuration
  is valid.

  It delegates calls around the bot processes to the bot factory supervisor.
  """

  use GenServer

  defmodule State do
    @moduledoc """
    Represents the state that is held within this process.
    """

    @type t :: %__MODULE__{
            factory_supervisor: pid(),
            config: map()
          }
    defstruct factory_supervisor: nil, config: %{}
  end

  # Client API

  @doc """
  Starts a `Superintendent` process linked to the current process
  with the configuration specified.
  """
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc """
  Connects a `Juvet.Bot` process with the Slack platform and the given parameters.
  """
  @spec connect_bot(pid(), atom(), map()) :: :ok
  def connect_bot(bot, :slack, %{team_id: _team_id} = parameters) do
    GenServer.cast(__MODULE__, {:connect_bot, bot, :slack, parameters})
  end

  @doc """
  Creates a `Juvet.Bot` process with the specified name under the
  `Juvet.FactorySupervisor`.

  ## Example

  ```
  {:ok, bot} = Juvet.Superintendent.create_bot("MyBot")
  ```
  """
  @spec create_bot(String.t()) :: {:ok, pid()} | {:error, any()}
  def create_bot(name) do
    GenServer.call(__MODULE__, {:create_bot, name})
  end

  @spec find_bot(String.t()) :: {:ok, pid()} | {:error, any()}
  def find_bot(name) do
    GenServer.call(__MODULE__, {:find_bot, name})
  end

  @doc """
  Returns the current state for the bot.

  ## Example

  ```
  state = Juvet.Superintendent.get_state(bot)
  ```
  """
  @spec get_state() :: map()
  def get_state, do: GenServer.call(__MODULE__, :get_state)

  # Server Callbacks

  @doc false
  @impl true
  def init(config) do
    if Juvet.Config.valid?(config) do
      send(self(), :start_factory_supervisor)
    end

    {:ok, %State{config: config}}
  end

  @doc false
  @impl true
  def handle_call(
        {:create_bot, name},
        _from,
        %{factory_supervisor: factory_supervisor, config: config} = state
      ) do
    reply = Juvet.FactorySupervisor.add_bot(factory_supervisor, config[:bot], name)

    {:reply, reply, state}
  end

  @doc false
  @impl true
  def handle_call(
        {:find_bot, name},
        _from,
        state
      ) do
    reply =
      case String.to_atom(name) |> Process.whereis() do
        nil -> {:error, "Bot named '#{name}' not found"}
        pid -> {:ok, pid}
      end

    {:reply, reply, state}
  end

  @doc false
  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, Map.from_struct(state)}
  end

  @doc false
  @impl true
  def handle_cast(
        {:connect_bot, bot, platform, parameters},
        %{config: config} = state
      ) do
    bot_module = Juvet.Config.bot(config)

    bot_module.connect(bot, platform, parameters)

    {:noreply, state}
  end

  @doc false
  @impl true
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
end
