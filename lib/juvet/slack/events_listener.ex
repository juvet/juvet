defmodule CowboyHandler do
  def init(_type, req, _opts) do
    {:ok, req, []}
  end

  def handle(request, state) do
    {:ok, reply} =
      :cowboy_req.reply(
        200,
        ["content-type", "text/html"],
        "<h1>Hello World</h1>"
      )

    {:ok, reply, state}
  end

  def terminate(_reason, _request, _state), do: :ok
end

defmodule Juvet.Slack.EventsListener do
  use GenServer

  # Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  # Server Callbacks

  def init(config) do
    start_server

    {:ok, %{config: config}}
  end

  defp start_server do
    dispatch_config =
      :cowboy_router.compile([
        {:_,
         [
           {:_, CowboyHandler, []}
         ]}
      ])

    :cowboy.start_http(:http, 100, [{:port, 8080}], [
      {:env, [:dispatch, dispatch_config]}
    ])
  end
end
