defmodule Juvet.Router.Platform do
  alias Juvet.Router.PlatformFactory

  defstruct platform: nil, routes: []

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def put_route(platform, route, options \\ %{}) do
    case validate_route(platform, route, options) do
      {:ok, route} ->
        routes = platform.routes
        {:ok, %{platform | routes: routes ++ [route]}}

      {:error, error} ->
        {:error, error}
    end
  end

  def validate_route(%__MODULE__{platform: platform}, route, options \\ %{}) do
    PlatformFactory.new(platform)
    |> PlatformFactory.validate_route(route, options)
  end
end
