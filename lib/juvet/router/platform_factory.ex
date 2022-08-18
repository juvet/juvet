defmodule Juvet.Router.PlatformFactory do
  @moduledoc """
  Module to create a `Juvet.Router.Platform` based on the Atom that is passed in.
  """

  alias Juvet.Router.UnknownPlatform

  def new(:unknown, platform), do: UnknownPlatform.new(platform)

  def new(platform) do
    platform_module(platform).new(platform)
  rescue
    _ in ArgumentError -> new(:unknown, platform)
  end

  def find_route(%Juvet.Router.Platform{} = platform, request) do
    platform_module(platform).find_route(new(platform), request)
  end

  def validate(%{__struct__: struct} = platform), do: struct.validate(platform)

  def validate_route(platform, route, options \\ %{})

  def validate_route(%{__struct__: struct} = platform, route, options) do
    platform |> struct.validate_route(route, options)
  end

  def validate_route(platform, route, options) do
    platform |> platform.validate_route(route, options)
  end

  defp platform_module(%Juvet.Router.Platform{platform: platform}),
    do:
      String.to_existing_atom(
        "Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Platform"
      )
end
