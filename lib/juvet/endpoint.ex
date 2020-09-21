defmodule Juvet.Endpoint do
  use Supervisor

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  def init(config) do
    endpoint = Access.get(config, :endpoint, Keyword.new())

    scheme =
      if endpoint[:https] || endpoint |> Keyword.has_key?(:https),
        do: :https,
        else: :http

    port =
      endpoint
      |> Access.get(scheme, Keyword.new())
      |> Access.get(:port, 80)

    children = [
      Plug.Cowboy.child_spec(
        scheme: scheme,
        plug: Juvet.Router,
        options: [port: port]
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
