defmodule Juvet.Router.SlackRouteHandler do
  @moduledoc """
  Handles default routes for the `SlackRouter`.
  """

  alias Juvet.Router.{Conn, Response}

  def handle_route(
        %{
          route: %{type: :url_verification},
          request: %{raw_params: %{"challenge" => challenge, "type" => "url_verification"}}
        } = context
      ) do
    conn =
      context
      |> Map.put(:response, Response.new(status: 200, body: %{challenge: challenge}))
      |> Conn.send_resp()

    context = Map.put(context, :conn, conn)

    {:ok, context}
  end
end
