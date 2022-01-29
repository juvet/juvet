defmodule Juvet.MiddlewareProcessor do
  def process(context) do
    Enum.reduce_while(context.middleware, {:ok, context}, fn middleware, {:ok, result} ->
      case process(middleware, result) do
        {:ok, ctx} -> {:cont, {:ok, ctx}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
  end

  def process(middleware, context) do
    apply(elem(middleware, 0), :call, [context])
  end
end
