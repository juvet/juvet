defmodule Juvet.MiddlewareProcessor do
  @moduledoc """
  Processes a list of middleware.
  """

  @doc """
  Enumerates through all of the middleware from within the `Context` and calls `call/1` with
  the provided middleware.

  If any of the middleware calls fail, process will immediately hault and return an `:error` tuple.
  """
  @spec process(map()) :: {:ok, map()} | {:error, any()}
  def process(context) do
    Enum.reduce_while(context.middleware, {:ok, context}, fn middleware, {:ok, result} ->
      case process(middleware, result) do
        {:ok, ctx} -> {:cont, {:ok, ctx}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  @doc """
  Processes a single piece of `Middleware` and returns the result.
  """
  @spec process(module(), map()) :: {:ok, map()} | {:error, any()}
  def process(middleware, context) do
    middleware.call(context)
  end
end
