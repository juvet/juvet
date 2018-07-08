defmodule Juvet.BotFactorySupervisor do
  use Supervisor

  @moduledoc """
  A supervisor that supervises a worker `BotFactory` process and
  another supervisor `BotSupervisor` which in turn, supervises all
  of the bot processes.
  """

  @doc ~S"""
  Starts a new bot factory supervisor

  Returns `{:ok, pid}` where `pid` is the process id of this supervisor.

  ## Example

  {:ok, pid} = Juvet.BotFactorySupervisor.start_link([bot: MyBot])
  """
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  ## Callbacks

  @doc false
  def init(config) do
    children = [
      worker(Juvet.BotFactory, [self(), config])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
