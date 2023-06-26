defmodule Juvet.Runner do
  @moduledoc """
  A module that takes in a map of variables as a context and runs the request through a
  collection of middleware.
  """

  alias Juvet.{Config, MiddlewareProcessor, Router}

  @doc """
  Gathers the configuration along with the specified `Context`, uses the specified
  `path`, it processes through the middleware and creates the endpoint to process a
  single specified route.
  """
  @spec route(String.t(), map()) :: {:ok, map()} | {:error, any()}
  def route(path, context \\ %{}) do
    {configuration, context} = Map.pop(context, :configuration)

    default_configuration(configuration)
    |> Map.merge(%{path: path})
    |> Map.merge(context)
    |> Map.delete(:conn)
    |> merge_middleware()
    |> MiddlewareProcessor.process()
  end

  @doc """
  Runs the request through the `Middleware` specifying the `Context` in order to
  find the correct route (path) and calls that endpoint generated from the request.
  """
  @spec run(Plug.Conn.t(), map()) :: {:ok, map()} | {:error, any()}
  def run(conn, context \\ %{}) do
    {configuration, context} = Map.pop(context, :configuration)

    default_configuration(configuration)
    |> Map.merge(%{conn: conn})
    |> Map.merge(context)
    |> merge_middleware()
    |> MiddlewareProcessor.process()
  end

  defp default_configuration(nil), do: %{configuration: Juvet.configuration()}

  defp default_configuration(configuration) do
    %{configuration: Keyword.merge(Juvet.configuration(), configuration)}
  end

  defp merge_middleware(%{configuration: configuration} = context) do
    partial = !Map.has_key?(context, :conn)

    configuration
    |> Config.router()
    |> Router.middlewares()
    |> Router.find_middleware(partial: partial)
    |> case do
      {:ok, middleware} ->
        middleware = middleware |> Enum.map(& &1.module)
        Map.merge(context, %{middleware: middleware})

      _ ->
        Map.merge(context, %{middleware: []})
    end
  end
end
