defmodule Juvet.PlugHelpers do
  @moduledoc """
  Test helpers for testing Plug tests.
  """

  defmacro __using__(_) do
    quote do
      use Plug.Test

      alias Plug.Conn

      def put_raw_body(%{params: %Plug.Conn.Unfetched{aspect: :params}} = conn),
        do: conn

      def put_raw_body(%{params: params} = conn) do
        Plug.Conn.put_private(conn, :juvet, %{
          raw_body: params |> ensure_encodable() |> URI.encode_query()
        })
      end

      def build_conn(method, path, params_or_body \\ nil, headers \\ nil)

      def build_conn(method, path, params_or_body, nil) do
        Plug.Adapters.Test.Conn.conn(
          %Conn{},
          method,
          path,
          params_or_body
        )
      end

      def build_conn(method, path, params_or_body, headers) do
        Plug.Adapters.Test.Conn.conn(
          %Conn{req_headers: headers},
          method,
          path,
          params_or_body
        )
      end

      def request!(
            method,
            path,
            params_or_body \\ nil,
            headers \\ nil,
            init_opts \\ []
          ) do
        build_conn(method, path, params_or_body, headers)
        |> put_raw_body()
        |> Juvet.Plug.call(Juvet.Plug.init(init_opts))
        |> from_set_to_sent()
      end

      defp ensure_encodable(map) do
        map
        |> Enum.reduce(%{}, fn {key, value}, encoded ->
          Map.merge(encoded, %{key => encode_value(value)})
        end)
      end

      defp encode_value(value) when is_map(value), do: URI.encode_query(value)
      defp encode_value(value), do: value

      defp from_set_to_sent(%Conn{state: :set} = conn), do: Conn.send_resp(conn)

      defp from_set_to_sent(conn), do: conn
    end
  end
end
