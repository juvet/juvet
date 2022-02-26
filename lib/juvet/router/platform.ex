defmodule Juvet.Router.Platform do
  @moduledoc """
  Represents a list of routes for a specific platform (e.g. `Slack`).
  """

  defstruct platform: nil, routes: []

  alias Juvet.Router.PlatformFactory

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

  def find_route(platform, request) do
    PlatformFactory.new(platform) |> PlatformFactory.find_route(request)
  end

  def validate(platform) do
    PlatformFactory.new(platform) |> PlatformFactory.validate()
  end

  def validate_route(platform, route, options \\ %{}) do
    PlatformFactory.new(platform)
    |> PlatformFactory.validate_route(route, options)
  end
end
