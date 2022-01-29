defmodule Juvet.Middleware.RouteRequest do
  alias Juvet.Router
  alias Juvet.Router.{Request, Route}

  def call(%{request: %Request{verified?: false} = request}),
    do:
      {:error,
       %Juvet.RoutingError{
         message: "Request was not verified.",
         request: request
       }}

  def call(
        %{
          configuration: configuration,
          request: %Request{verified?: true} = request
        } = context
      ) do
    case get_router(configuration) do
      {:ok, router} ->
        case Router.find_route(router, request) do
          {:ok, route} ->
            {:ok,
             Map.merge(context, %{
               path: Route.path(route),
               route: route
             })}

          {:error, :not_found} ->
            {:error,
             %Juvet.RoutingError{
               message: "No route found for the request.",
               request: request
             }}
        end

      {:error, {:invalid_router, invalid_router}} ->
        router_name = invalid_router |> to_string |> router_name()

        {:error,
         %Juvet.ConfigurationError{
           message: "Router #{router_name} configured in Juvet configuration is not found."
         }}

      {:error, :missing_router} ->
        {:error,
         %Juvet.ConfigurationError{
           message: "Router missing in Juvet configuration."
         }}
    end
  end

  defp get_router(configuration) do
    case Keyword.get(configuration, :router) do
      router when not is_nil(router) ->
        case Router.exists?(router) do
          true -> {:ok, router}
          false -> {:error, {:invalid_router, router}}
        end

      _ ->
        {:error, :missing_router}
    end
  end

  defp router_name("Elixir." <> name), do: name
  defp router_name(name), do: name
end
