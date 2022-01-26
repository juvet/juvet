defmodule Juvet.PlugHelpers do
  @moduledoc """
  Test helpers for testing Plug tests.
  """

  defmacro __using__(_) do
    quote do
      use Plug.Test

      alias Plug.Conn

      def put_raw_body(%{params: params} = conn) do
        Plug.Conn.put_private(conn, :juvet, %{
          raw_body: params |> URI.encode_query()
        })
      end

      defp request!(method, path, params_or_body \\ nil, headers \\ nil) do
        build_conn(method, path, params_or_body, headers)
        |> Juvet.Plug.call(Juvet.Plug.init([]))
        |> from_set_to_sent()
      end

      defp build_conn(method, path, params_or_body, nil) do
        Plug.Adapters.Test.Conn.conn(
          %Conn{},
          method,
          path,
          params_or_body
        )
      end

      defp build_conn(method, path, params_or_body, headers) do
        Plug.Adapters.Test.Conn.conn(
          %Conn{req_headers: headers},
          method,
          path,
          params_or_body
        )
      end

      defp from_set_to_sent(%Conn{state: :set} = conn), do: Conn.send_resp(conn)

      defp from_set_to_sent(conn), do: conn
    end
  end
end
