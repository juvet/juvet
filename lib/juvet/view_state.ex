defmodule Juvet.ViewState do
  @moduledoc """
  A process that can be used to store and retrieve changes across network requests.
  """

  use GenServer

  alias Juvet.ViewStateRegistry

  @registry ViewStateRegistry

  @type t :: %__MODULE__{
          key: tuple() | binary(),
          value: any(),
          pid: pid()
        }
  defstruct key: nil,
            value: nil,
            pid: nil

  @spec exists?(pid()) :: true | false
  def exists?(pid_or_key) when is_pid(pid_or_key), do: Process.alive?(pid_or_key)

  @spec exists?(tuple() | binary()) :: true | false
  def exists?(pid_or_key) do
    case @registry.whereis_name(pid_or_key) do
      :undefined -> false
      _ -> GenServer.call(via(pid_or_key), :exists?)
    end
  end

  @spec start(tuple() | binary(), any(), keyword()) :: {:ok, pid()} | {:error, any()}
  def start(key, value, opts \\ []) do
    GenServer.start(__MODULE__, %__MODULE__{key: key, value: value}, opts)
  end

  @spec start_link(tuple() | binary(), any(), keyword()) :: {:ok, pid()} | {:error, any()}
  def start_link(key, value, opts \\ []) do
    GenServer.start_link(__MODULE__, %__MODULE__{key: key, value: value}, opts)
  end

  @spec state(pid() | tuple() | binary()) :: Tatsu.Bot.ViewState.t() | nil
  def state(pid_or_key), do: GenServer.call(via(pid_or_key), :state)

  @spec stop(pid() | tuple() | binary()) :: Tatsu.Bot.ViewState.t() | nil
  def stop(pid_or_key), do: GenServer.call(via(pid_or_key), :stop)

  @spec update(pid() | tuple(), any()) :: :ok
  def update(pid_or_key, value), do: GenServer.cast(via(pid_or_key), {:update, value})

  @spec value(pid() | tuple() | binary()) :: any()
  def value(pid_or_key), do: GenServer.call(via(pid_or_key), :value)

  # Callbacks
  def init(%__MODULE__{key: key} = state) do
    pid = self()

    @registry.register_name(key, pid)

    {:ok, %{state | pid: pid}}
  end

  def handle_call(:exists?, _from, %__MODULE__{value: value} = state) do
    {:reply, !!value, state}
  end

  def handle_call(:state, _from, %__MODULE__{} = state) do
    {:reply, state, state}
  end

  def handle_call(:stop, _from, %__MODULE__{} = state) do
    {:stop, :normal, state, state}
  end

  def handle_call(:value, _from, %__MODULE__{} = state) do
    {:reply, state.value, state}
  end

  def handle_cast({:update, value}, %__MODULE__{} = state) do
    {:noreply, %{state | value: value}}
  end

  defp via(pid_or_key) when is_pid(pid_or_key), do: pid_or_key

  defp via(key), do: {:via, @registry, key}
end
