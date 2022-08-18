defmodule Juvet.Router.UnknownRouter do
  @moduledoc """
  Represents a `Juvet.Router` that could not be idenfied for a platform definition.
  """

  defstruct platform: :unknown

  def new(platform) do
    %__MODULE__{platform: platform}
  end

  def validate(_platform), do: {:error, :unknown_platform}

  def validate_route(platform, route, options \\ %{}) do
    {:error, {:unknown_platform, [platform: platform, route: route, options: options]}}
  end
end
