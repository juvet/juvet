defmodule Juvet.Middleware.ActionRunner do
  @moduledoc """
  Middleware to retrieve the controller module and action function and calls
  that function with the `Juvet.Context` that was created.
  """

  @spec call(map()) :: {:ok, map()} | {:error, any()}
  def call(%{action: action} = context) do
    m = elem(action, 0)
    f = elem(action, 1)

    try do
      case apply(m, f, [context]) do
        {:ok, ctx} when is_map(ctx) ->
          {:ok, ctx}

        {:error, error} ->
          {:error, error}

        _ ->
          {:error,
           "`#{f}/1` is required to return the `context` in an `:ok` tuple or an `:error` tuple"}
      end
    rescue
      UndefinedFunctionError -> {:error, "`#{m}.#{f}/1` is not defined"}
    end
  end

  def call(_context), do: {:error, "`action` missing in the `context`"}
end
