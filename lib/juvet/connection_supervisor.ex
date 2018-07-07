defmodule Juvet.ConnectionSupervisor do
  use DynamicSupervisor

  def start_link() do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Callbacks

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
