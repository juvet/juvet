defmodule Juvet.Router.PlatformFactory do
  @moduledoc """
  Module to create a `Juvet.Router.Platform` based on the Atom that is passed in.
  """

  alias Juvet.Router.UnknownPlatform

  def new(platform), do: router(platform).new(platform)

  def find_route(%Juvet.Router.Platform{} = platform, request) do
    router(platform).find_route(new(platform), request)
  end

  # TODO: This name will make sense in a bit
  def router(%Juvet.Router.Platform{platform: platform}) do
    String.to_existing_atom("Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Platform")
  rescue
    _ in ArgumentError -> UnknownPlatform
  end

  def validate_route(%Juvet.Router.Platform{} = platform, route, options \\ %{}) do
    router(platform).validate_route(new(platform), route, options)
  end
end
