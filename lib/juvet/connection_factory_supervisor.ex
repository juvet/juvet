defmodule Juvet.ConnectionFactorySupervisor do
  use Supervisor

  @moduledoc """
  A supervisor that supervises a worker `ConnectionFactory` process and
  another supervisor `ConnectionSupervisor` which in turn, supervises all
  of the connection processes.
  """

  @doc ~S"""
  Starts a new connection factory supervisor

  Returns `{:ok, pid}` where `pid` is the process id of this supervisor.

  ## Example

  {:ok, pid} = Juvet.ConnectionFactorySupervisor.start_link()
  """
  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## Callbacks

  @doc false
  def init(_args) do
    children = [
      worker(Juvet.ConnectionFactory, [self()])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
