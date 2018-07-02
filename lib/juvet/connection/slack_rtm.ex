defmodule Juvet.Connection.SlackRTM do
  use WebSockex

  alias Juvet.{SlackAPI}

  def connect(%{token: _token} = parameters) do
    SlackAPI.RTM.connect(parameters)
    |> start_link
  end

  def handle_frame({type, msg} = message, state) do
    # TODO: Could receive error from Slack WebSocket here:
    # {type: "error", error: { msg: "Socket URL has expired", code: 1, source: "" }}
    PubSub.publish(:incoming_slack_message, message)

    {:ok, state}
  end

  defp start_link({:ok, %{url: url}}) do
    WebSockex.start_link(url, __MODULE__, %{})
  end

  defp start_link({:error, _} = response), do: response
end
