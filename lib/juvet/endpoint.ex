defmodule Juvet.Endpoint do
  use Supervisor

  def start_link(args = %{scheme: _scheme}) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args = %{scheme: scheme}) do
    options = Map.merge(%{options: []}, args).options

    children = [
      Plug.Cowboy.child_spec(
        scheme: scheme,
        plug: Juvet.Router,
        options: options
      )
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
