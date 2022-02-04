defmodule Juvet.Router.Conn do
  @moduledoc """
  Wrapper for sending a response to the `Plug.Conn` contained within the context based on
  the response built within the same context.
  """

  def send_resp(%{conn: conn, response: %{body: body, status: status}}, options \\ []) do
    halt = Keyword.get(options, :halt, true)

    Plug.Conn.send_resp(conn, status, body)
    |> maybe_halt(halt)
  end

  defp maybe_halt(conn, false), do: conn
  defp maybe_halt(conn, true), do: conn |> Plug.Conn.halt()
end
