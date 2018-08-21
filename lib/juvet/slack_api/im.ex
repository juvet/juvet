defmodule Juvet.SlackAPI.IM do
  alias Juvet.SlackAPI

  @moduledoc """
  A wrapper around the im methods on the Slack API.
  """

  @doc ~S"""
  Requests a new IM channel between the requestor and the user specified.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    no_op: true,
    channel: {
      id: "D123456"
    }
  } = Juvet.SlackAPI.IM.open(%{token: token, user: user})
  """

  def open(options \\ %{}) do
    SlackAPI.request("im.open", options)
    |> SlackAPI.render_response()
  end
end
