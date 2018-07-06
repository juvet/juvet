defmodule Juvet.Connection.SlackRTM do
  use WebSockex

  alias Juvet.{SlackAPI}

  def connect(%{token: _token} = parameters) do
    SlackAPI.RTM.connect(parameters)
    |> start_link
  end

  def get_state(pid) do
    {:ok, :sys.get_state(pid)}
  end

  def handle_connect(_conn, %{ok: true} = state) do
    PubSub.publish(:new_slack_connection, [:new_slack_connection, state])

    {:ok, state}
  end

  def handle_disconnect(_, state) do
    PubSub.publish(:slack_disconnected, [:slack_disconnected, state])

    {:ok, state}
  end

  def handle_frame({_type, message}, state) do
    PubSub.publish(:incoming_slack_message, [:incoming_slack_message, message])

    {:ok, state}
  end

  defp start_link({:ok, %{url: url} = response}) do
    WebSockex.start_link(url, __MODULE__, response)
  end

  defp start_link({:error, _} = response), do: response
end
