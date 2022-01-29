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
    with {:ok, router} <- get_router(configuration) do
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
    else
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
    with router when not is_nil(router) <- Keyword.get(configuration, :router) do
      case Router.exists?(router) do
        true -> {:ok, router}
        false -> {:error, {:invalid_router, router}}
      end
    else
      _ ->
        {:error, :missing_router}
    end
  end

  defp router_name("Elixir." <> name), do: name
  defp router_name(name), do: name
end
