defmodule Juvet.Middleware.ActionRunner do
  def call(%{action: action} = context) do
    m = elem(action, 0)
    f = elem(action, 1)

    try do
      apply(m, f, [context])
    rescue
      UndefinedFunctionError -> {:error, "`#{m}.#{f}/1` is not defined"}
    else
      _ ->
        {:ok, context}
    end
  end

  def call(_context), do: {:error, "`action` missing in the `context`"}
end
