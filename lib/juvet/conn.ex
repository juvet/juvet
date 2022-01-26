defmodule Juvet.Conn do
  @moduledoc """
  Functions to make working with a `Plug.Conn` easier and more consistent.
  """

  @private_key :juvet

  def put_private(%Plug.Conn{} = conn, value) when is_map(value) do
    current = get_private(conn, %{})
    Plug.Conn.put_private(conn, @private_key, Map.merge(current, value))
  end

  def get_private(%Plug.Conn{private: private}, default \\ nil) do
    private[@private_key] || default
  end
end
