defmodule Juvet.SlackActionRoute do
  @moduledoc """
  Plug to handle any action from Slack.
  """

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack actions API endpoint.
  """
  def call(conn, _opts), do: Juvet.Router.Conn.run(conn)
end
