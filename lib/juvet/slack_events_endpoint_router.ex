defmodule Juvet.SlackEventsEndpointRouter do
  @moduledoc """
  Endpoint router to handle all messages for Slack events.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack events API endpoint.
  """
  def call(conn, _opts) do
    send_resp(conn, 200, "")
  end
end
