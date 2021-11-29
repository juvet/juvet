defmodule Juvet.Router.UnknownPlatform do
  defstruct platform: nil

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def validate_route(platform, route, options \\ %{}) do
    {:error,
     {:unknown_platform, [platform: platform, route: route, options: options]}}
  end
end
