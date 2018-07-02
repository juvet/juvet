defmodule Juvet.FakeSlack do
  def start_link(url \\ "http://localhost:51345") do
    uri = URI.parse(url)

    # This is used by the application config so it can be pluggable
    Application.put_env(:slack, :url, url)

    Plug.Adapters.Cowboy.http(
      __MODULE__,
      [],
      port: uri.port,
      dispatch: dispatch()
    )
  end

  def stop do
    Plug.Adapters.Cowboy.shutdown(Slack.FakeSlack.Websocket)
  end

  defp dispatch do
    [
      {
        :_,
        [
          {"/ws", Juvet.FakeSlack.Websocket, []}
        ]
      }
    ]
  end
end
