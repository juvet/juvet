defmodule Juvet.FakeSlack do
  alias Juvet.FakeSlack

  def start_link(url \\ "http://localhost:51345") do
    # This is used by the application config so it can be pluggable
    Application.put_env(:slack, :url, url)

    uri = URI.parse(url)

    Plug.Adapters.Cowboy.http(
      __MODULE__,
      [],
      port: uri.port,
      dispatch: dispatch()
    )
  end

  def set_client_pid(pid) do
    FakeSlack.Websocket.set_client_pid(pid)
  end

  def stop do
    Plug.Adapters.Cowboy.shutdown(FakeSlack.Websocket)
  end

  defp dispatch do
    [
      {
        :_,
        [
          {"/ws", FakeSlack.Websocket, []}
        ]
      }
    ]
  end
end
