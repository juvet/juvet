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
  Request to retrieve to close a a direct message or multi-person direct message.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true
  } = Juvet.SlackAPI.Conversations.close(%{token: token, channel: "C12345"})
  """

  @spec close(map()) :: {:ok, map()} | {:error, map()}
  def close(options \\ %{}) do
    SlackAPI.make_request("conversations.close", options)
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
  Request to retrieve to invites users to a channel.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel:%{
      id: "C12345",
      name: "CHANNEL1",
      is_channel: true
    }
  } = Juvet.SlackAPI.Conversations.invite(%{token: token, channel: "C12345", users: ["U12345", "U67890"]})
  """

  @spec invite(map()) :: {:ok, map()} | {:error, map()}
  def invite(options \\ %{}) do
    SlackAPI.make_request("conversations.invite", options |> transform_options())
    |> SlackAPI.render_response()
  end

  @doc """
  Request to join an existing conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel:%{
      id: "C12345",
      name: "CHANNEL1",
      is_channel: true
    }
  } = Juvet.SlackAPI.Conversations.join(%{token: token, channel: "C12345"})
  """

  @spec join(map()) :: {:ok, map()} | {:error, map()}
  def join(options \\ %{}) do
    SlackAPI.make_request("conversations.join", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Request to remove a user from a conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true
  } = Juvet.SlackAPI.Conversations.kick(%{token: token, channel: "C12345", user: "U12345"})
  """

  @spec kick(map()) :: {:ok, map()} | {:error, map()}
  def kick(options \\ %{}) do
    SlackAPI.make_request("conversations.kick", options |> transform_options())
    |> SlackAPI.render_response()
  end

  @doc """
  Request to leave a conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true
  } = Juvet.SlackAPI.Conversations.leave(%{token: token, channel: "C12345"})
  """

  @spec leave(map()) :: {:ok, map()} | {:error, map()}
  def leave(options \\ %{}) do
    SlackAPI.make_request("conversations.leave", options)
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
    SlackAPI.make_request("conversations.open", options |> transform_options())
    |> SlackAPI.render_response()
  end

  @doc """
  Requests a rename for a conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel: {
      id: "D123456"
    }
  } = Juvet.SlackAPI.Conversations.rename(%{token: token, channel: "C12345", name: "something-new"})
  """

  @spec rename(map()) :: {:ok, map()} | {:error, map()}
  def rename(options \\ %{}) do
    SlackAPI.make_request("conversations.rename", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Requests a sets the purpose for a conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    purpose: "It's so very special"
  } = Juvet.SlackAPI.Conversations.set_purpose(%{token: token, channel: "C12345", purpuse: "It's so very special"})
  """

  @spec set_purpose(map()) :: {:ok, map()} | {:error, map()}
  def set_purpose(options \\ %{}) do
    SlackAPI.make_request("conversations.setPurpose", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Requests a set the topic for a conversation.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel: {
      id: "D123456"
    }
  } = Juvet.SlackAPI.Conversations.set_topic(%{token: token, channel: "C12345", topic: "Let's chat about this..."})
  """

  @spec set_topic(map()) :: {:ok, map()} | {:error, map()}
  def set_topic(options \\ %{}) do
    SlackAPI.make_request("conversations.setTopic", options)
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
