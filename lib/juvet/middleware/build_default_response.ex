defmodule Juvet.Middleware.BuildDefaultResponse do
  @moduledoc """
  Middleware to create a default `Juvet.Router.Response` for the request that is
  contained within the context.
  """

  alias Juvet.Router.{OAuthRouter, RequestIdentifier, Response}

  @spec call(map()) :: {:ok, map()}
  def call(%{request: _request} = context),
    do: {:ok, Map.put_new(context, :response, default_response(context))}

  def call(context), do: {:ok, context}

  defp default_response(%{configuration: configuration, request: request, route: route}) do
    if RequestIdentifier.oauth?(request, configuration),
      do: default_oauth_response(request, route, configuration),
      else: Response.new(status: 200)
  end

  defp default_oauth_response(%{platform: platform}, %{route: phase}, configuration) do
    Response.new(
      body: OAuthRouter.url_for(platform, phase, configuration),
      status: 302
    )
  end
end
