defmodule Juvet.Router.Route do
  @moduledoc """
  Represents a single route that is defined within the `Juvet.Router`.
  """

  @type t :: %__MODULE__{
          type: atom(),
          route: String.t(),
          options: keyword()
        }
  defstruct type: nil, route: nil, options: []

  def new(type, route, options \\ []) do
    %__MODULE__{type: type, route: route, options: options}
  end

  def path(%{options: options}) do
    Keyword.get(options, :to)
  end
end
