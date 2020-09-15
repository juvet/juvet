defmodule Juvet.Endpoint do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(_config) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Juvet.Router,
        options: [port: 8080]
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
