defmodule Juvet.Router.Platform do
  @moduledoc """
  Represents a list of routes for a specific platform (e.g. `Slack`).
  """

  @type t :: %__MODULE__{
          platform: atom() | nil,
          routes: list(Juvet.Router.Route.t())
        }
  defstruct platform: nil, routes: []

  alias Juvet.Router.PlatformFactory

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def put_route(%Juvet.Router.Platform{} = platform, route, options \\ %{}) do
    case PlatformFactory.validate_route(platform, route, options) do
      {:ok, route} ->
        routes = platform.routes
        {:ok, %{platform | routes: routes ++ [route]}}

      {:error, error} ->
        {:error, error}
    end
  end

  def validate(%Juvet.Router.Platform{} = platform),
    do: PlatformFactory.router(platform).validate(platform)
end
