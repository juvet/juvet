defmodule Juvet.PlugHelpers do
  @moduledoc """
  Test helpers for testing Plug tests.
  """

  defmacro __using__(_) do
    quote do
      use Plug.Test

      defp request!(method, path, params_or_body \\ nil) do
        conn(method, path, params_or_body)
        |> Juvet.EndpointRouter.call(Juvet.EndpointRouter.init([]))
      end
    end
  end
end
