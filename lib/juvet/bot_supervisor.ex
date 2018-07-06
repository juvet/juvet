defmodule Juvet.BotSupervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks

  def init(_args) do
    supervise([], strategy: :one_for_one)
  end
end
