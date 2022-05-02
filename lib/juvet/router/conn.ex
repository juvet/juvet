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

  def run(conn) do
    config = get_config(conn)
    context = get_context(conn)

    case Juvet.Runner.run(conn, Map.merge(%{configuration: config}, context)) do
      {:ok, context} ->
        maybe_send_response(context)

      {:error, error} ->
        send_error(conn, error)
    end
  end

  def send_resp(%{conn: conn, response: %{body: body, status: status}}, options \\ []) do
    case already_sent?(conn) do
      true ->
        conn

      false ->
        halt = Keyword.get(options, :halt, true)

        response_body = format_response_body(body)

        conn
        |> put_headers(body)
        |> Plug.Conn.send_resp(status, response_body)
        |> set_sent()
        |> maybe_halt(halt)
    end
  end

  defp already_sent?(%Plug.Conn{} = conn) do
    !is_nil(get_response_sent(get_private(conn)))
  end

  defp format_response_body(body) when is_map(body), do: body |> Poison.encode!()
  defp format_response_body(body), do: body

  defp get_config(%Plug.Conn{} = conn), do: get_config(get_private(conn))

  defp get_config(%{options: options}) do
    get_in(options, [:configuration]) || []
  end

  defp get_config(_), do: []

  defp get_context(%Plug.Conn{} = conn), do: get_context(get_private(conn))

  defp get_context(%{options: options}) do
    get_in(options, [:context]) || %{}
  end

  defp get_response_sent(%{response_sent: response_sent}), do: response_sent
  defp get_response_sent(_), do: nil

  defp maybe_halt(conn, false), do: conn
  defp maybe_halt(conn, true), do: conn |> Plug.Conn.halt()

  defp maybe_send_response(%{conn: %{state: :chunked} = conn}), do: conn
  defp maybe_send_response(%{conn: %{state: :sent} = conn}), do: conn

  defp maybe_send_response(%{conn: _conn} = context), do: send_resp(context)

  defp put_headers(conn, body) when is_map(body),
    do: conn |> Plug.Conn.put_resp_content_type("application/json")

  defp put_headers(conn, _body), do: conn

  defp send_error(conn, _error), do: conn |> Plug.Conn.send_resp(200, "")

  defp set_sent(%Plug.Conn{} = conn) do
    conn |> put_private(%{response_sent: NaiveDateTime.utc_now()})
  end
end
