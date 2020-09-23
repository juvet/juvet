defmodule Juvet.Endpoint do
  use Supervisor

  def start_link(_state \\ []) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: Juvet.Config.scheme(),
        plug: Juvet.Router,
        options: [port: Juvet.Config.port()]
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
