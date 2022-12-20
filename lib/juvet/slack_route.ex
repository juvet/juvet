defmodule Juvet.SlackRoute do
  @moduledoc """
  Plug to handle any request from Slack.
  """

  alias Juvet.Router.Conn

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack API endpoints.
  """
  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, _opts), do: Conn.run(conn)
end
