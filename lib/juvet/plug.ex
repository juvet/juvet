defmodule Juvet.Plug do
  @moduledoc """
  Specifies the routing for any incoming messages.

  Includes routing for Slack as well as a catch all as a last
  resort to return a 404.
  """

  use Plug.Router
  use Juvet.SlackRoutes

  alias Juvet.Router.Conn

  @doc false
  @impl true
  def init(opts) do
    config = Keyword.get(opts, :configuration, Juvet.configuration())

    Keyword.merge(opts, configuration: config)
  end

  unless Mix.env() == :test, do: plug(Plug.Logger)
  plug(:insert_juvet_options, builder_opts())
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json, :multipart, :urlencoded],
    pass: ["*/*"],
    body_reader: {Juvet.CacheBodyReader, :read_body, []},
    json_decoder: Poison
  )

  plug(:dispatch)

  match(_, do: conn)

  defp insert_juvet_options(conn, opts), do: Conn.put_private(conn, %{options: opts})
end
