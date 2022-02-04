defmodule Juvet.Router.Conn do
  @moduledoc """
  Wrapper for sending a response to the `Plug.Conn` contained within the context based on
  the response built within the same context.
  """

  @private_key :juvet

  def get_private(%Plug.Conn{private: private}, default \\ nil) do
    private[@private_key] || default
  end

  def put_private(%Plug.Conn{} = conn, value) when is_map(value) do
    current = get_private(conn, %{})
    Plug.Conn.put_private(conn, @private_key, Map.merge(current, value))
  end

  def private_key, do: @private_key

  def send_resp(%{conn: conn, response: %{body: body, status: status}}, options \\ []) do
    halt = Keyword.get(options, :halt, true)

    Plug.Conn.send_resp(conn, status, body)
    |> maybe_halt(halt)
  end

  defp maybe_halt(conn, false), do: conn
  defp maybe_halt(conn, true), do: conn |> Plug.Conn.halt()
end
