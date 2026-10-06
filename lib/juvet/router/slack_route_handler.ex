defmodule Juvet.Router.SlackRouteHandler do
  @moduledoc """
  Handles default routes for the `SlackRouter`.
  """

  alias Juvet.{Config, Router}
  alias Juvet.OAuth.State
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
          conn: conn,
          route: %{type: :oauth, route: "callback"},
          request: %{raw_params: %{"code" => _code} = params}
        } = context
      ) do
    case State.verify(conn, params, configuration) do
      :ok ->
        context
        |> delete_oauth_state()
        |> authorize()

      {:error, :invalid_state} ->
        context
        |> delete_oauth_state()
        |> Map.put(:error, :invalid_state)
        |> route_oauth_or_error("error")

      {:error, _error} = error ->
        error
    end
  end

  def handle_route(
        %{
          route: %{type: :oauth, route: "callback"},
          request: %{
            raw_params: %{"error" => error, "error_description" => error_description}
          }
        } = context
      ) do
    context
    |> delete_oauth_state()
    |> Map.put(:error, error)
    |> Map.put(:error_description, error_description)
    |> route_oauth_or_error("error")
  end

  defp authorize(
         %{
           configuration: configuration,
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

  defp delete_oauth_state(%{configuration: configuration, conn: conn} = context),
    do: Map.put(context, :conn, State.delete(conn, configuration))

  defp delete_oauth_state(context), do: context

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
