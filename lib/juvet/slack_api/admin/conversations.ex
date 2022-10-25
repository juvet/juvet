defmodule Juvet.SlackAPI.Admin.Conversations do
  @moduledoc """
  A wrapper around the administration conversations methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Request to create a public or private channel-based conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel_id: "C12345"
  } = Juvet.SlackAPI.Admin.Conversations.create(%{token: token, name: "CHANNEL1"})
  """

  @spec create(map()) :: {:ok, map()} | {:error, map()}
  def create(options \\ %{}), do: render_response_to("admin.conversations.create", options)

  defp render_response_to(endpoint, options) do
    SlackAPI.make_request(endpoint, options)
    |> SlackAPI.render_response()
  end
end
