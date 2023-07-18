defmodule Juvet.Router.RouteFinder do
  @moduledoc """
  Finds a specific `Juvet.Router.Route` based on a `Juvet.Router.Request`.
  """

  alias Juvet.Router.RouterFactory

  @spec find(list(Juvet.Router.Platform.t()), Juvet.Router.Request.t(), keyword()) ::
          {:ok, Juvet.Router.Route.t()} | {:error, any()}
  def find(platforms, request, opts \\ []) do
    route =
      Enum.map(platforms, fn platform ->
        case find_route(platform, request, opts) do
          {:error, _error} -> nil
          {:ok, route} -> route
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> List.first()

    case route do
      nil -> {:error, :not_found}
      route -> {:ok, route}
    end
  end

  @spec find_route(Juvet.Router.Platform.t(), Juvet.Router.Request.t(), keyword()) ::
          {:ok, Juvet.Router.Route.t()} | {:error, any()}
  def find_route(platform, request, opts \\ []),
    do: RouterFactory.find_route(platform, request, opts)
end
