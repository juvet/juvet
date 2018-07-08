defmodule Juvet.Connection.SlackRTM do
  use WebSockex

  @moduledoc """
  A process to start a websocket connection to the Slack RTM api.
  """

  alias Juvet.{SlackAPI}

  @doc ~S"""
  Makes a call to the Slack API RTM.connect endpoint with the specified
  `token` and uses that url to connect to the websocket server on Slack.

  ## Example

  {:ok, pid} = Juvet.Connection.SlackRTM.connect(%{token: token})
  """
  def connect(%{token: _token} = parameters) do
    SlackAPI.RTM.connect(parameters)
    |> start_link
  end

  @doc ~S"""
    Returns the current state of the Slack process.

    ## Example

    {:ok, pid} = Juvet.Connection.SlackRTM.get_state(pid)
  """
  def get_state(pid) do
    {:ok, :sys.get_state(pid)}
  end

  def handle_connect(_conn, %{ok: true} = state) do
    PubSub.publish(:new_slack_connection, [:new_slack_connection, state])

    {:ok, state}
  end

  @doc ~S"""
  Handles when the SlackRTM receives a disconnected message from PubSub.
  """
  def handle_disconnect(_, state) do
    PubSub.publish(:slack_disconnected, [:slack_disconnected, state])

    {:ok, state}
  end

  @doc ~S"""
  Handles when the SlackRTM receives a incoming message from PubSub.
  """
  def handle_frame({_type, message}, %{team: %{id: id}} = state) do
    PubSub.publish(:"incoming_slack_message_#{id}", [
      :incoming_slack_message,
      message
    ])

    {:ok, state}
  end

  @doc false
  defp start_link({:ok, %{url: url} = response}) do
    WebSockex.start_link(url, __MODULE__, response)
  end

  @doc false
  defp start_link({:error, _} = response), do: response
end
