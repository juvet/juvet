defmodule Juvet.BotSupervisor do
  use DynamicSupervisor

  def start_link(_args \\ []) do
    DynamicSupervisor.start_link(__MODULE__, :ok, [])
  end

  # Callbacks

  def init(:ok) do
    opts = [strategy: :one_for_one]

    DynamicSupervisor.init(opts)
  end
end
