defmodule Juvet.SlackCommandRoute do
  @moduledoc """
  Plug to handle any command from Slack.
  """

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack commands API endpoint.
  """
  def call(conn, _opts), do: Juvet.Router.Conn.run(conn)
end
