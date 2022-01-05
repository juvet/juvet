defmodule Juvet.CacheBodyReader do
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = put_raw_body(conn, body)
    {:ok, body, conn}
  end

  defp put_raw_body(%Plug.Conn{private: %{juvet: juvet}} = conn, body) do
    juvet = Map.merge(juvet, raw_body_map(body))

    Plug.Conn.put_private(conn, :juvet, juvet)
  end

  defp put_raw_body(conn, body),
    do: Plug.Conn.put_private(conn, :juvet, raw_body_map(body))

  defp raw_body_map(body) do
    opts = %{raw_body: nil}

    update_in(opts[:raw_body], &[body | &1 || []])
  end
end
