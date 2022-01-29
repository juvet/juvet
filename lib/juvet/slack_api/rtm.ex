defmodule Juvet.SlackAPI.RTM do
  @moduledoc """
  A wrapper around the rtm methods on the Slack API.
  """

  alias Juvet.SlackAPI

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
  def connect(options \\ %{}) do
    SlackAPI.make_request("rtm.connect", options)
    |> SlackAPI.render_response()
  end
end
