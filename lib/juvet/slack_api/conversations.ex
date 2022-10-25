defmodule Juvet.SlackAPI.Conversations do
  @moduledoc """
  A wrapper around the conversations methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Request to retrieve to archive a conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true
  } = Juvet.SlackAPI.Conversations.archive(%{token: token, channel: "C12345"})
  """

  @spec archive(map()) :: {:ok, map()} | {:error, map()}
  def archive(options \\ %{}) do
    SlackAPI.make_request("conversations.archive", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Request to retrieve to initiate a public or private channel-based conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel:%{
      id: "C12345",
      name: "CHANNEL1",
      is_channel: true
    }
  } = Juvet.SlackAPI.Conversations.create(%{token: token, name: "CHANNEL1"})
  """

  @spec create(map()) :: {:ok, map()} | {:error, map()}
  def create(options \\ %{}) do
    SlackAPI.make_request("conversations.create", options)
    |> SlackAPI.render_response()
  end

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

  @spec members(map()) :: {:ok, map()} | {:error, map()}
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

  @spec open(map()) :: {:ok, map()} | {:error, map()}
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
