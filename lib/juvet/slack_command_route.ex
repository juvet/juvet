defmodule Juvet.SlackCommandRoute do
  @moduledoc """
  Plug to handle any command from Slack.
  """

  alias Juvet.Router.Conn

  @doc false
  def init(opts), do: opts

  @doc """
  Handles web requests targeted for the Slack commands API endpoint.
  """
  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, _opts), do: Conn.run(conn)
end
