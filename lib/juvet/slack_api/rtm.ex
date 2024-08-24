defmodule Juvet.SlackAPI.RTM do
  @moduledoc """
  A wrapper around the rtm methods on the Slack API.
  """

  use Juvet.SlackAPI.Endpoint

  @doc """
  Requests a new connection via websockets for the Slack API
  and retrieves a websocket address as well as some information
  about the team and the user that requested the connection.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    url: "ws://...",
    self: %{
      id: "U01234",
      name: "Jimmy Page"
    },
    team: %{
      domain: "Led Zeppelin",
      id: "T67328"
    }
  } = Juvet.Connection.SlackRTM.connect(%{token: token})
  """
  @spec connect(map()) :: {:ok, map()} | {:error, map()}
  def connect(options \\ %{}), do: request_and_render("rtm.connect", options)
end
