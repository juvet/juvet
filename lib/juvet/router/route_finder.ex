defmodule Juvet.Router.RouteFinder do
  @moduledoc """
  Finds a specific `Juvet.Router.Route` based on a `Juvet.Router.Request`.
  """

  alias Juvet.Router.Platform

  def find(platforms, request) do
    route =
      Enum.map(platforms, fn platform ->
        case find_route(platform, request) do
          {:error, _error} -> nil
          {:ok, route} -> route
        end
      end)
      |> List.first()

    case route do
      nil -> {:error, :not_found}
      route -> {:ok, route}
    end
  end

  def find_route(platform, request) do
    Platform.find_route(platform, request)
  end
end
