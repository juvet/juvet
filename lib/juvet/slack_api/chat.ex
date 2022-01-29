defmodule Juvet.SlackAPI.Chat do
  @moduledoc """
  A wrapper around the chat methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Creates a new message and sends it to the channel specified.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    message: {
      text: "Hello World"
    }
  } = Juvet.SlackAPI.Chat.post_message(%{token: token, channel: channel, text: text})
  """

  def post_message(options \\ %{}) do
    SlackAPI.make_request("chat.postMessage", options)
    |> SlackAPI.render_response()
  end
end
