defmodule Juvet.Router.Platform do
  @moduledoc """
  Represents a list of routes for a specific platform (e.g. `Slack`).
  """

  @type t :: %__MODULE__{
          platform: atom() | nil,
          routes: list(Juvet.Router.Route.t())
        }
  defstruct platform: nil, routes: []

  alias Juvet.Router.RouterFactory

  @spec new(atom()) :: Juvet.Router.Platform.t()
  def new(platform) do
    %__MODULE__{platform: platform}
  end

  @spec put_default_routes(Juvet.Router.Platform.t()) ::
          {:ok, Juvet.Router.Platform.t()} | {:error, any()}
  def put_default_routes(platform) do
    case RouterFactory.get_default_routes(platform) do
      {:ok, routes} ->
        current_routes = platform.routes
        {:ok, %{platform | routes: current_routes ++ routes}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec put_route(Juvet.Router.Platform.t(), Juvet.Router.Route.t(), keyword()) ::
          {:ok, Juvet.Router.Platform.t()} | {:error, any()}
  def put_route(%Juvet.Router.Platform{} = platform, route, opts \\ []) do
    case RouterFactory.validate_route(platform, route, opts) do
      {:ok, route} ->
        routes = platform.routes
        {:ok, %{platform | routes: routes ++ [route]}}

      {:error, error} ->
        {:error, error}
    end
  end

  @spec validate(Juvet.Router.Platform.t()) :: {:ok, Juvet.Router.Platform.t()} | {:error, any()}
  def validate(%Juvet.Router.Platform{} = platform),
    do: RouterFactory.router(platform).validate(platform)
end
