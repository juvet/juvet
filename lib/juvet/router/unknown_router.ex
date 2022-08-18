defmodule Juvet.Router.UnknownRouter do
  @moduledoc """
  Represents a `Juvet.Router` that could not be idenfied for a platform definition.
  """

  @type t :: %__MODULE__{
          platform: Juvet.Router.Platform.t()
        }
  defstruct platform: nil

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def validate(_platform), do: {:error, :unknown_platform}

  def validate_route(router, route, options \\ %{}) do
    {:error, {:unknown_platform, [router: router, route: route, options: options]}}
  end
end
