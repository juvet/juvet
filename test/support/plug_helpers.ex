defmodule Juvet.PlugHelpers do
  @moduledoc """
  Test helpers for testing Plug tests.
  """

  defmacro __using__(_) do
    quote do
      use Plug.Test

      defp request!(method, path, params_or_body \\ nil, headers \\ nil) do
        conn(method, path, params_or_body)
        |> put_request_headers(headers)
        |> Juvet.Plug.call(Juvet.Plug.init([]))
      end

      defp put_request_headers(conn, nil), do: conn

      defp put_request_headers(conn, headers) do
        Enum.each(headers, fn {key, value} ->
          conn = conn |> put_req_header(to_string(key), value)
        end)

        conn
      end
    end
  end
end
