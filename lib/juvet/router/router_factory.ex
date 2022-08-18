defmodule Juvet.Router.RouterFactory do
  @moduledoc """
  Module to create a `Juvet.Router` based on the `Juvet.Router.Platform` that is passed in.
  """

  alias Juvet.Router.UnknownRouter

  def find_route(%Juvet.Router.Platform{} = platform, request) do
    router(platform).find_route(to_router(platform), request)
  end

  def router(%Juvet.Router.Platform{platform: platform}) do
    String.to_existing_atom("Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Platform")
  rescue
    _ in ArgumentError -> UnknownRouter
  end

  def validate_route(%Juvet.Router.Platform{} = platform, route, options \\ %{}) do
    router(platform).validate_route(to_router(platform), route, options)
  end

  defp to_router(%Juvet.Router.Platform{} = platform), do: router(platform).new(platform)
end
