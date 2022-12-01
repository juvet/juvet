defmodule Juvet.ViewStateRegistry do
  @moduledoc """
  A process to keep track of what view state keys are registered. It is used as a Registry
  for other processes for the view state in order to exchange a list of tuples for a name.
  """

  use GenServer

  @name :view_state_registry

  def name, do: @name

  @spec start_link(any()) :: {:ok, pid()} | {:error, any()}
  def start_link(_), do: GenServer.start_link(__MODULE__, [], name: name())

  @spec start_link() :: {:ok, pid()} | {:error, any()}
  def start_link, do: GenServer.start_link(__MODULE__, [], name: name())

  @spec stop() :: :ok
  def stop, do: GenServer.call(name(), :stop)

  @spec register_name(tuple() | binary(), pid()) :: :ok | :already_registered
  def register_name(name, pid), do: GenServer.call(name(), {:register_name, name, pid})

  @spec send(tuple() | binary(), any()) :: pid() | {:badarg, {tuple() | binary(), any()}}
  def send(name, message) do
    case whereis_name(name) do
      :undefined ->
        {:badarg, {name, message}}

      pid ->
        Kernel.send(pid, message)
        pid
    end
  end

  @spec unregister_name(tuple() | binary()) :: :ok
  def unregister_name(name), do: GenServer.cast(name(), {:unregister_name, name})

  @spec whereis_name(tuple() | binary()) :: pid() | :undefined
  def whereis_name(name), do: GenServer.call(name(), {:whereis_name, name})

  # Callbacks

  def init(_) do
    {:ok, Map.new()}
  end

  def handle_call({:register_name, name, pid}, _from, state) do
    case state |> find_by_name(name) do
      :undefined ->
        Process.monitor(pid)
        {:reply, :ok, state |> Map.put_new(name, pid)}

      _ ->
        {:reply, :already_registered, state}
    end
  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, state, state}
  end

  def handle_call({:whereis_name, name}, _from, state) do
    {:reply, state |> find_by_name(name), state}
  end

  def handle_cast({:unregister_name, name}, state) do
    {:noreply, state |> Map.delete(name)}
  end

  def handle_info({:DOWN, _, :process, pid, _}, state) do
    {:noreply, state |> remove_by_pid(pid)}
  end

  defp find_by_name(state, name), do: state |> Map.get(name, :undefined)

  defp remove_by_pid(state, pid_to_remove) do
    state
    |> Enum.reject(fn {_key, pid} -> pid == pid_to_remove end)
    |> Enum.into(%{})
  end
end
