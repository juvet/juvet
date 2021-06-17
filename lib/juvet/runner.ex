defmodule Juvet.Runner do
  alias Juvet.{Middleware, MiddlewareProcessor}

  def route(path, context \\ %{}) do
    %{configuration: Juvet.configuration()}
    |> Map.merge(%{path: path})
    |> Map.merge(context)
    |> Map.merge(%{middleware: Middleware.group(:partial)})
    |> MiddlewareProcessor.process()
  end
end
