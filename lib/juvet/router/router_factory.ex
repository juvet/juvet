defmodule Juvet.Router.RouterFactory do
  @moduledoc """
  Module to create a `Juvet.Router` based on the `Juvet.Router.Platform` that is passed in.
  """

  alias Juvet.Router.UnknownRouter

  @spec find_route(Juvet.Router.Platform.t(), Juvet.Router.Request.t()) ::
          {:ok, Juvet.Router.Route.t()} | {:error, any()}
  def find_route(%Juvet.Router.Platform{} = platform, request) do
    router(platform).find_route(to_router(platform), request)
  end

  @spec get_default_routes(Juvet.Router.Platform.t()) ::
          {:ok, list(Juvet.Router.Route.t())} | {:error, any()}
  def get_default_routes(platform) do
    router(platform).get_default_routes()
  end

  @spec router(Juvet.Router.Platform.t()) :: module()
  def router(%Juvet.Router.Platform{platform: platform}) do
    String.to_existing_atom("Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Router")
  rescue
    _ in ArgumentError -> UnknownRouter
  end

  @spec validate_route(Juvet.Router.Platform.t(), Juvet.Router.Route.t(), map()) ::
          {:ok, Juvet.Router.Route.t()} | {:error, any()}
  def validate_route(%Juvet.Router.Platform{} = platform, route, options \\ %{}) do
    router(platform).validate_route(to_router(platform), route, options)
  end

  defp to_router(%Juvet.Router.Platform{} = platform), do: router(platform).new(platform)
end
