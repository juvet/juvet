defmodule Juvet.MiddlewareProcessor do
  def process(context) do
    Enum.reduce(context.middleware, context, &process/2)
  end

  def process(middleware, context) do
    apply(elem(middleware, 0), :call, [context])
  end
end
