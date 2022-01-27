defmodule Juvet.Router.Route do
  defstruct type: nil, route: nil, options: []

  def new(type, route, options \\ []) do
    %__MODULE__{type: type, route: route, options: options}
  end

  def path(%{options: options}) do
    Keyword.get(options, :to)
  end
end
