defmodule Juvet.Middleware.BuildDefaultResponse do
  @moduledoc """
  Middleware to create a default `Juvet.Router.Response` for the request that is
  contained within the context.
  """

  alias Juvet.Router.{OAuthRouter, RequestIdentifier, Response}

  @spec call(map()) :: {:ok, map()}
  def call(%{request: _request} = context), do: {:ok, maybe_put_response(context)}

  def call(context), do: {:ok, context}

  defp maybe_put_response(context) do
    case request_type(context) do
      :oauth_request_phase -> Map.put_new(context, :response, default_oauth_response(context))
      :oauth_callback_phase -> context
      _ -> Map.put_new(context, :response, Response.new(status: 200))
    end
  end

  defp request_type(context) do
    cond do
      oauth_request_phase?(context) -> :oauth_request_phase
      oauth_request?(context) -> :oauth_callback_phase
      true -> :platform
    end
  end

  defp oauth_request?(%{configuration: configuration, request: request}),
    do: RequestIdentifier.oauth?(request, configuration)

  defp oauth_request_phase?(%{route: %{route: "request"}} = context), do: oauth_request?(context)
  defp oauth_request_phase?(_context), do: false

  defp default_oauth_response(%{
         configuration: configuration,
         request: %{platform: platform},
         route: %{route: phase}
       }) do
    Response.new(
      body: OAuthRouter.url_for(platform, phase, configuration),
      status: 302
    )
  end
end
