defmodule Juvet.FakeSlack do
  @moduledoc """
  Process to start a websocket at a specified url and receives amd dispatches
  requests from the websocket.
  """

  alias Juvet.FakeSlack.Websocket
  alias Plug.Adapters.Cowboy

  def start_link(url \\ "http://localhost:51345") do
    # This is used by the application config so it can be pluggable
    Application.put_env(:slack, :url, url)

    uri = URI.parse(url)

    Cowboy.http(
      __MODULE__,
      [],
      port: uri.port,
      dispatch: dispatch()
    )
  end

  def set_client_pid(pid) do
    Websocket.set_client_pid(pid)
  end

  def stop do
    Cowboy.shutdown(Websocket)
  end

  defp dispatch do
    [
      {
        :_,
        [
          {"/ws", Websocket, []}
        ]
      }
    ]
  end
end
