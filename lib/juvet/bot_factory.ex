defmodule Juvet.BotFactory do
  use Supervisor

  @moduledoc """
  The top-level Supervisor for the whole factory floor.
  """

  # Client API

  def start_link(_args \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  # Server Callbacks

  def init(:ok) do
    children = [
      Juvet.Superintendent
    ]

    opts = [strategy: :one_for_all]

    Supervisor.init(children, opts)
  end
end
