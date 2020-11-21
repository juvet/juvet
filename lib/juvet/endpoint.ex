defmodule Juvet.Endpoint do
  @moduledoc """
  Process to listen for incoming message from a configured web endpoint.
  """

  use Supervisor

  @doc """
  Starts a process to listen for messages with the specified endpoint `config`.

  ## Options

  * `endpoint` - Keyword list that specifies the configuration for the endpoint
                 including the scheme and options.
  """
  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc false
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
