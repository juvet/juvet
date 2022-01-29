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
      {:ok, _context} ->
        send_resp(conn, 200, "")
        |> halt()

      {:error, error} ->
        send_error(conn, error)
    end
  end

  defp get_config(%Plug.Conn{} = conn),
    do: get_config(Juvet.Conn.get_private(conn))

  defp get_config(%{options: options}) do
    get_in(options, [:configuration]) || []
  end

  defp get_config(_), do: []

  defp get_context(%Plug.Conn{} = conn),
    do: get_context(Juvet.Conn.get_private(conn))

  defp get_context(%{options: options}) do
    get_in(options, [:context]) || %{}
  end

  defp get_context(_), do: %{}

  defp send_error(conn, _error), do: conn |> send_resp(200, "")
end
