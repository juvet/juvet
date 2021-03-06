defmodule Juvet.EndpointRouter do
  @moduledoc """
  Specifies the routing for any incoming messages.

  Includes routing for Slack as well as a catch all as a last
  resort to return a 404.
  """

  use Plug.Router
  use Juvet.SlackEndpointRouter, config: Juvet.configuration()

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:dispatch)

  # TODO: Make this response configurable like in Phoenix
  match(_, do: send_resp(conn, 404, "Oh no! This route is not handled in Juvet"))
end
