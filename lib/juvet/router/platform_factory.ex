defmodule Juvet.Router.PlatformFactory do
  def new(:unknown), do: Juvet.Router.UnknownPlatform

  def new(platform) do
    try do
      String.to_existing_atom(
        "Elixir.Juvet.Router.#{Macro.camelize(to_string(platform))}Platform"
      )
    rescue
      _ in ArgumentError -> new(:unknown)
    end
  end

  def validate_route(platform, route, options \\ %{}) do
    platform.validate_route(route, options)
  end
end
