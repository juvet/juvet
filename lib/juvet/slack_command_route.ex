defmodule Juvet.SlackCommandRoute do
  @moduledoc """
  Plug to handle any command from Slack.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack commands API endpoint.
  """
  def call(conn, _opts) do
    config = get_config(conn)
    context = get_context(conn)

    case Juvet.Runner.run(conn, Map.merge(%{configuration: config}, context)) do
      {:ok, context} ->
        maybe_send_response(context)

      {:error, error} ->
        send_error(conn, error)
    end
  end

  defp get_config(%Plug.Conn{} = conn),
    do: get_config(Juvet.Router.Conn.get_private(conn))

  defp get_config(%{options: options}) do
    get_in(options, [:configuration]) || []
  end

  defp get_config(_), do: []

  defp get_context(%Plug.Conn{} = conn),
    do: get_context(Juvet.Router.Conn.get_private(conn))

  defp get_context(%{options: options}) do
    get_in(options, [:context]) || %{}
  end

  defp get_context(_), do: %{}

  defp send_error(conn, _error), do: conn |> send_resp(200, "")

  defp maybe_send_response(%{conn: %{state: :chunked} = conn}), do: conn
  defp maybe_send_response(%{conn: %{state: :sent} = conn}), do: conn

  defp maybe_send_response(%{conn: _conn} = context), do: Juvet.Router.Conn.send_resp(context)
end
