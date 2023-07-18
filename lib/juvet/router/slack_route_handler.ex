defmodule Juvet.Router.SlackRouteHandler do
  @moduledoc """
  Handles default routes for the `SlackRouter`.
  """

  alias Juvet.{Config, Router}
  alias Juvet.Router.{Conn, OAuthRouter, Response}

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

  def handle_route(
        %{
          configuration: configuration,
          route: %{type: :oauth, route: "callback"},
          request: %{platform: platform, raw_params: %{"code" => code}}
        } = context
      ) do
    case OAuthRouter.auth_for(platform, configuration, code: code) do
      {:ok, response} ->
        context
        |> Map.put(:auth_response, response)
        |> route_oauth_or_error("success")

      {:error, error, response} ->
        context
        |> Map.put(:error, error)
        |> Map.put(:error_response, response)
        |> route_oauth_or_error("error")
    end
  end

  defp route_oauth_or_error(
         %{configuration: configuration, request: %{platform: platform}} = context,
         route
       ) do
    router = Config.router(configuration)

    case Router.find_path(router, platform, :oauth, route) do
      {:ok, path} -> Router.route(path, context)
      {:error, error} -> {:error, error}
    end
  end
end
