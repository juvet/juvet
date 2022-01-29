defmodule Juvet.Router.PlatformFactory do
  @moduledoc """
  Module to create a `Juvet.Router.Platform` based on the Atom that is passed in.
  """

  alias Juvet.Router.UnknownPlatform

  def new(:unknown, platform), do: UnknownPlatform.new(platform)

  def new(platform) do
    mod =
      String.to_existing_atom(
        "Elixir.Juvet.Router.#{Macro.camelize(to_string(platform.platform))}Platform"
      )

    mod.new(platform)
  rescue
    _ in ArgumentError -> new(:unknown, platform)
  end

  def find_route(platform, request)

  def find_route(%{__struct__: struct} = platform, request) do
    platform |> struct.find_route(request)
  end

  def find_route(platform, request) do
    platform |> platform.find_route(request)
  end

  def validate_route(platform, route, options \\ %{})

  def validate_route(%{__struct__: struct} = platform, route, options) do
    platform |> struct.validate_route(route, options)
  end

  def validate_route(platform, route, options) do
    platform |> platform.validate_route(route, options)
  end
end
