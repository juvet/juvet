defmodule Juvet.SlackActionsEndpointRouter do
  @moduledoc """
  Endpoint router to handle all messages for Slack actions.
  """

  import Plug.Conn

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack actions API endpoint.
  """
  def call(conn, _opts) do
    send_resp(conn, 200, "")
  end
end
