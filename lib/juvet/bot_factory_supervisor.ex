defmodule Juvet.BotFactorySupervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  # Callbacks
  def init(_args) do
    children = [
      worker(Juvet.BotFactory, [self(), []])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
