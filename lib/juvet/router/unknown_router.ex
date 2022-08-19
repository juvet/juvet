defmodule Juvet.Router.UnknownRouter do
  @moduledoc """
  Represents a `Juvet.Router` that could not be idenfied for a platform definition.
  """

  @behaviour Juvet.Router

  @type t :: %__MODULE__{
          platform: Juvet.Router.Platform.t()
        }
  defstruct platform: nil

  @impl Juvet.Router
  def new(platform) do
    %__MODULE__{platform: platform}
  end

  @impl Juvet.Router
  def find_route(platform, request),
    do: {:error, {:unknown_route, [platform: platform, request: request]}}

  @impl Juvet.Router
  def validate(_platform), do: {:error, :unknown_platform}

  @impl Juvet.Router
  def validate_route(router, route, options \\ %{}) do
    {:error, {:unknown_platform, [router: router, route: route, options: options]}}
  end
end
