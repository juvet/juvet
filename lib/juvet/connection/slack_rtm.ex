defmodule Juvet.Connection.SlackRTM do
  use WebSockex

  alias Juvet.{SlackAPI}

  def start(%{token: _token} = parameters) do
    SlackAPI.RTM.connect(parameters)
    |> start_link
  end

  def handle_frame({type, msg}, state) do
    # TODO: Could receive error from Slack WebSocket here:
    # {type: "error", error: { msg: "Socket URL has expired", code: 1, source: "" }}
    IO.puts(
      "Received Message - Type: #{inspect(type)} -- Message: #{inspect(msg)}"
    )

    {:ok, state}
  end

  defp start_link({:ok, %{url: url}}) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  defp start_link({:error, _} = response), do: response
end
