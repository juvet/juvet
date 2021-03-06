defmodule Juvet.SlackAPI.Conversations do
  @moduledoc """
  A wrapper around the conversations methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Requests a new Conversation between the requestor and the users or channel specified.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel: {
      id: "D123456"
    }
  } = Juvet.SlackAPI.Conversations.open(%{token: token, users: [user]})
  """

  def open(options \\ %{}) do
    SlackAPI.request("conversations.open", options)
    |> SlackAPI.render_response()
  end
end
