defmodule Juvet.Middleware.ActionRunner do
  @moduledoc """
  Middleware to retrieve the controller module and action function and calls
  that function with the `Juvet.Context` that was created.
  """

  @spec call(map()) :: {:ok, map()} | {:error, any()}
  def call(%{action: {m, f}} = context) do
    case apply(m, f, [context]) do
      {:ok, ctx} when is_map(ctx) -> {:ok, ctx}
      {:error, error} -> {:error, error}
      _ -> {:error, invalid_return_error("#{f}/1")}
    end
  rescue
    UndefinedFunctionError -> {:error, not_defined_error("#{m}.#{f}/1")}
  end

  def call(%{action: fun} = context) do
    case fun.(context) do
      {:ok, ctx} when is_map(ctx) -> {:ok, ctx}
      {:error, error} -> {:error, error}
      _ -> {:error, invalid_return_error(inspect(fun))}
    end
  rescue
    e in BadArityError -> {:error, e.function}
    UndefinedFunctionError -> {:error, not_defined_error(inspect(fun))}
  end

  def call(_context), do: {:error, "`action` missing in the `context`"}

  defp invalid_return_error(function_name),
    do:
      "`#{function_name}` is required to return the `context` in an `:ok` tuple or an `:error` tuple"

  defp not_defined_error(function_name), do: "`#{function_name}` is not defined"
end
