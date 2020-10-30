defmodule Juvet.Connection.SlackRTM do
  use WebSockex

  @moduledoc """
  A process to start a websocket connection to the Slack RTM api.
  """

  alias Juvet.{SlackAPI}

  defmodule State do
    defstruct receiver: nil, message: nil
  end

  @doc ~S"""
  Makes a call to the Slack API RTM.connect endpoint with the specified
  `token` and uses that url to connect to the websocket server on Slack.

  ## Example

  {:ok, pid} = Juvet.Connection.SlackRTM.connect(pid, %{token: token})
  """
  def connect(receiver, %{token: _token} = parameters) do
    state = %State{receiver: receiver}

    SlackAPI.RTM.connect(parameters)
    |> (&Kernel.put_in(state.message, &1)).()
    |> start_link
  end

  @doc ~S"""
    Returns the last message received from the connection.

    ## Example

    {:ok, message} = Juvet.Connection.SlackRTM.get_message(pid)
  """
  def get_message(pid) do
    %{message: {_, body}} = :sys.get_state(pid)

    {:ok, body}
  end

  def handle_connect(_conn, state = %{receiver: receiver, message: {_, body}}) do
    send(receiver, {:connected, :slack, body})

    {:ok, state}
  end

  @doc ~S"""
  Handles when the SlackRTM receives a disconnected message from the websocket.
  """
  def handle_disconnect(_, state = %{receiver: receiver, message: {_, body}}) do
    send(receiver, {:disconnected, :slack, body})

    {:ok, state}
  end

  @doc ~S"""
  Handles when the SlackRTM receives a incoming message from the websocket.
  """
  def handle_frame({_type, message}, state = %{receiver: receiver}) do
    send(receiver, {:new_message, :slack, message})

    {:ok, %{state | message: {:ok, message}}}
  end

  @doc false
  defp start_link(state = %State{message: {:ok, %{url: url}}}) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  @doc false
  defp start_link(%State{message: {:error, _error} = response}), do: response
end
