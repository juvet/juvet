defmodule Juvet.SlackEventsEndpointRouter do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _config) do
    send_resp(conn, 200, "")
  end
end
