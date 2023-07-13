defmodule Juvet.Router.UnknownRouter do
  @moduledoc """
  Represents a `Juvet.Router` that could not be idenfied for a platform definition.
  """

  @behaviour Juvet.Router

  @type t :: %__MODULE__{
          platform: Juvet.Router.Platform.t()
        }
  defstruct platform: nil

  @spec new(atom()) :: Juvet.Router.UnknownRouter.t()
  @impl Juvet.Router
  def new(platform) do
    %__MODULE__{platform: platform}
  end

  @impl Juvet.Router
  def find_route(platform, request, opts \\ []),
    do: {:error, {:unknown_route, [platform: platform, request: request, opts: opts]}}

  @impl Juvet.Router
  def get_default_routes, do: {:error, :unknown_platform}

  @impl Juvet.Router
  def handle_route(_context), do: {:error, :unknown_platform}

  @impl Juvet.Router
  def request_format(_request), do: {:error, :unknown_platform}

  @impl Juvet.Router
  def validate(_platform), do: {:error, :unknown_platform}

  @impl Juvet.Router
  def validate_route(router, route, opts \\ []) do
    {:error, {:unknown_platform, [router: router, route: route, opts: opts]}}
  end
end
