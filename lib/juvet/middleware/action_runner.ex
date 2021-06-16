defmodule Juvet.Middleware.ActionRunner do
  def call(%{action: action} = context) do
    m = elem(action, 0)
    f = elem(action, 1)

    apply(m, f, [context])

    {:ok, context}
  end

  def call(_context), do: {:error, "`action` missing in the `context`"}
end
