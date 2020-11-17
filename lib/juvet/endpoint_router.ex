defmodule Juvet.EndpointRouter do
  use Plug.Router
  use Juvet.SlackEndpointRouter, config: Application.get_all_env(:juvet)

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  # TODO: Make this response configurable like in Phoenix
  match(_, do: send_resp(conn, 404, "Oh no! This route is not handled in Juvet"))
end
