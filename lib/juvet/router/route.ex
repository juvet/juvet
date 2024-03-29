defmodule Juvet.Router.Route do
  @moduledoc """
  Represents a single route that is defined within the `Juvet.Router`.
  """

  @type t :: %__MODULE__{
          type: atom(),
          route: String.t() | nil,
          options: keyword()
        }
  defstruct type: nil, route: nil, options: []

  @spec new(atom(), String.t() | nil, keyword()) :: Juvet.Router.Route.t()
  def new(type, route \\ nil, options \\ []) do
    %__MODULE__{type: type, route: route, options: options}
  end

  def match?(%__MODULE__{} = subject, type, route) do
    to_string(subject.type) == to_string(type) && to_string(subject.route) == to_string(route)
  end

  @spec path(map()) :: String.t() | function()
  def path(%{options: options}) do
    Keyword.get(options, :to)
  end
end
