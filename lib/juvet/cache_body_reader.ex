defmodule Juvet.CacheBodyReader do
  @moduledoc """
  Stores the raw body in private `Juvet` area in the `Plug.Conn`
  for verification purposes.
  """
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = put_raw_body(conn, body)
    {:ok, body, conn}
  end

  defp put_raw_body(%Plug.Conn{} = conn, body) do
    Juvet.Conn.put_private(conn, raw_body_map(body))
  end

  defp raw_body_map(body) do
    opts = %{raw_body: nil}

    update_in(opts[:raw_body], &[body | &1 || []])
  end
end
