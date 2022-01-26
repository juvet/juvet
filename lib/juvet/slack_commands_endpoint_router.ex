defmodule Juvet.SlackCommandsEndpointRouter do
  @moduledoc """
  Endpoint router to handle all messages for Slack commands.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack commands API endpoint.
  """
  def call(conn, config) do
    case Juvet.Runner.run(conn, %{configuration: config}) do
      {:ok, _context} ->
        send_resp(conn, 200, "")
        |> halt()

      {:error, error} ->
        send_error(conn, error)
    end
  end

  # TODO: Do something clever here
  defp send_error(conn, _error), do: conn |> send_resp(200, "")
end
