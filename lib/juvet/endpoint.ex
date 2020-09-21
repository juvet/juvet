defmodule Juvet.Endpoint do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    port =
      Access.get(
        Access.get(
          Access.get(config, :endpoint, Keyword.new()),
          :http,
          Keyword.new()
        ),
        :port,
        8080
      )

    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Juvet.Router,
        options: [port: port]
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
