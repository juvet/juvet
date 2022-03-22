defmodule Juvet.SlackAPI.Conversations do
  @moduledoc """
  A wrapper around the conversations methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Request to retrieve all the user ids for the users within a Conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    members:[
      "USER1",
      "USER2"
    ]
  } = Juvet.SlackAPI.Conversations.members(%{token: token, channel: "CHANNEL1"})
  """

  def members(options \\ %{}) do
    SlackAPI.make_request("conversations.members", options)
    |> SlackAPI.render_response()
  end

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
    options = options |> transform_options

    SlackAPI.make_request("conversations.open", options)
    |> SlackAPI.render_response()
  end

  defp encode_users(nil), do: nil
  defp encode_users(users), do: Enum.join(users, ",")

  defp transform_options(options) do
    options
    |> Map.get_and_update(:users, &{&1, encode_users(&1)})
    |> elem(1)
    |> Enum.filter(fn {_key, value} -> !is_nil(value) end)
    |> Enum.into(%{})
  end
end
