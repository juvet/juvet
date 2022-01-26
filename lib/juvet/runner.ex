defmodule Juvet.Runner do
  alias Juvet.{Middleware, MiddlewareProcessor}

  def route(path, context \\ %{}) do
    {configuration, context} = Map.pop(context, :configuration)

    default_configuration(configuration)
    |> Map.merge(%{path: path})
    |> Map.merge(context)
    |> Map.merge(%{middleware: Middleware.group(:partial)})
    |> MiddlewareProcessor.process()
  end

  def run(conn, context \\ %{}) do
    {configuration, context} = Map.pop(context, :configuration)

    default_configuration(configuration)
    |> Map.merge(%{conn: conn})
    |> Map.merge(context)
    |> Map.merge(%{middleware: Middleware.group(:all)})
    |> MiddlewareProcessor.process()
  end

  defp default_configuration(nil), do: %{configuration: Juvet.configuration()}

  defp default_configuration(configuration) do
    %{configuration: Keyword.merge(Juvet.configuration(), configuration)}
  end
end
