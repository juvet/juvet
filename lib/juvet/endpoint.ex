defmodule Juvet.Endpoint do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    [{scheme, options}] = Juvet.Config.endpoint(config)

    children = [
      Plug.Cowboy.child_spec(
        scheme: scheme,
        plug: Juvet.EndpointRouter,
        options: options
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
