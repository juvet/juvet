defmodule Juvet.EndpointRouter do
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  def call(conn, config) do
    case Juvet.Config.slack(config) do
      %{actions_endpoint: _actions_endpoint} -> IO.puts("Found actions")
      %{events_endpoint: _events_endpoint} -> IO.puts("Found events")
    end

    unquote(do: match(_, do: send_resp(conn, 404, "oops ... Nothing here :(")))

    super(conn, config)
  end
end
