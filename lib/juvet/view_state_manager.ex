defmodule Juvet.ViewStateManager do
  @moduledoc """
  A Supervisor process to handle the management of all the view state processes.
  """

  use Supervisor

  alias Juvet.{ViewState, ViewStateRegistry}

  @name __MODULE__
  @supervisor :view_state_supervisor

  def name, do: @name

  def start_link(_), do: start_link()
  def start_link, do: Supervisor.start_link(__MODULE__, [], name: name())

  def stop, do: Supervisor.stop(name())

  def retrieve(key), do: ViewState.value(key)

  def remove(key), do: ViewState.stop(key)

  def state(key), do: ViewState.state(key)

  def store(key, value) do
    case ViewState.exists?(key) do
      true -> update_child(key, value)
      false -> start_child(key, value)
    end
  end

  defp start_child(key, value) do
    DynamicSupervisor.start_child(
      @supervisor,
      %{
        id: {ViewState, key},
        start: {ViewState, :start_link, [key, value]},
        restart: :transient
      }
    )
  end

  defp update_child(key, value) do
    :ok = ViewState.update(key, value)

    case ViewState.state(key) do
      %{pid: pid} -> {:ok, pid}
      nil -> {:error, :key_not_found}
    end
  end

  # Callbacks

  @impl true
  def init(_) do
    children = [
      ViewStateRegistry,
      {DynamicSupervisor, name: @supervisor, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
