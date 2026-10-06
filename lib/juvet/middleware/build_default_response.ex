defmodule Juvet.Middleware.BuildDefaultResponse do
  @moduledoc """
  Middleware to create a default `Juvet.Router.Response` for the request that is
  contained within the context.

  For the OAuth request phase, the default response redirects to the OAuth provider
  with a `state` that is stored in a signed cookie (see `Juvet.OAuth.State`).
  """

  alias Juvet.OAuth.State
  alias Juvet.Router.{OAuthRouter, RequestIdentifier, Response}

  @spec call(map()) :: {:ok, map()} | {:error, any()}
  def call(%{request: _request} = context), do: maybe_put_response(context)

  def call(context), do: {:ok, context}

  defp maybe_put_response(%{response: _response} = context), do: {:ok, context}

  defp maybe_put_response(context) do
    if oauth_request_phase?(context),
      do: put_oauth_response(context),
      else: {:ok, Map.put(context, :response, Response.new(status: 200))}
  end

  defp oauth_request?(%{configuration: configuration, request: request}),
    do: RequestIdentifier.oauth?(request, configuration)

  defp oauth_request_phase?(%{route: %{route: "request"}} = context), do: oauth_request?(context)
  defp oauth_request_phase?(_context), do: false

  defp put_oauth_response(
         %{
           configuration: configuration,
           conn: conn,
           request: %{platform: platform},
           route: %{route: phase}
         } = context
       ) do
    with {:ok, conn, state} <- State.put(conn, configuration) do
      response =
        Response.new(
          body: OAuthRouter.url_for(platform, phase, configuration, state: state),
          status: 302
        )

      {:ok, context |> Map.put(:conn, conn) |> Map.put(:response, response)}
    end
  end
end
