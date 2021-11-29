defmodule Juvet.Router.PlatformFactory do
  def new(:unknown, platform), do: Juvet.Router.UnknownPlatform.new(platform)

  def new(platform) do
    try do
      String.to_existing_atom(
        "Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Platform"
      )
    rescue
      _ in ArgumentError -> new(:unknown, platform)
    end
  end

  def validate_route(platform, route, options \\ %{})

  def validate_route(%{__struct__: struct} = platform, route, options) do
    platform |> struct.validate_route(route, options)
  end

  def validate_route(platform, route, options) do
    platform |> platform.validate_route(route, options)
  end
end
