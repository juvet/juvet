defmodule Juvet.Router.Platform do
  alias Juvet.Router.PlatformFactory

  defstruct platform: nil, routes: []

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def validate_route(%__MODULE__{platform: platform}, route, options \\ %{}) do
    PlatformFactory.new(platform)
    |> PlatformFactory.validate_route(route, options)
  end
end
