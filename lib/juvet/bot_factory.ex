defmodule Juvet.BotFactory do
  use Supervisor

  @moduledoc """
  The top-level Supervisor for the whole factory floor.
  """

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def create(name) do
    Juvet.Superintendent.create_bot(name)
  end

  # Callbacks

  def init(config) do
    children = [
      {Juvet.Superintendent, config}
    ]

    opts = [strategy: :one_for_all]

    Supervisor.init(children, opts)
  end
end
