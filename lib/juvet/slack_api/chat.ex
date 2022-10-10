defmodule Juvet.SlackAPI.Chat do
  @moduledoc """
  A wrapper around the chat methods on the Slack API.
  """

  alias Juvet.SlackAPI

  @doc """
  Deletes a pending scheduled message.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true
  } = Juvet.SlackAPI.Chat.delete_scheduled_message(%{token: token, channel: channel, scheduled_message_id: id})
  """
  @spec delete_scheduled_message(map()) :: {:ok, map()} | {:error, map()}
  def delete_scheduled_message(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.deleteScheduledMessage", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Retrieve a permalink URL for a specific extant message.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel: "C12345",
    permalink: "https://slack.com/archives/M12345"
  } = Juvet.SlackAPI.Chat.get_permalink(%{token: token, channel: channel, message_ts: ts})
  """
  @spec get_permalink(map()) :: {:ok, map()} | {:error, map()}
  def get_permalink(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.getPermalink", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Share a me message into a channel.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel: "C12345",
    ts: "1417671948.000006"
  } = Juvet.SlackAPI.Chat.me_message(%{token: token, channel: channel, text: text})
  """
  @spec me_message(map()) :: {:ok, map()} | {:error, map()}
  def me_message(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.meMessage", options)
    |> SlackAPI.render_response()
  end

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
  @spec post_message(map()) :: {:ok, map()} | {:error, map()}
  def post_message(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.postMessage", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Schedules a new message for a specific timestamp and sends it to the channel specified.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    channel: "C12345",
    scheduled_message_id: "Q12345",
    post_at: "1562180400",
    message: {
      text: "Hello World"
    }
  } = Juvet.SlackAPI.Chat.schedule_message(%{token: token, channel: channel, post_at: post_at, text: text})
  """
  @spec schedule_message(map()) :: {:ok, map()} | {:error, map()}
  def schedule_message(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.scheduleMessage", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Returns a list of scheduled messages.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    scheduled_messages: [%{
      id: "Q12345",
      channel_id: "C12345",
      post_at: "1562180400",
      text: "Hello World"
    }]
  } = Juvet.SlackAPI.Chat.schedule_messages_list(%{token: token})
  """
  @spec scheduled_messages_list(map()) :: {:ok, map()} | {:error, map()}
  def scheduled_messages_list(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.scheduledMessages.list", options)
    |> SlackAPI.render_response()
  end

  @doc """
  Updates an existing message based on the timestamp and sends it to the channel specified.

  Returns a map of the Slack response.

  ## Example

  %{
    ok: true,
    ts: "12345678.19872",
    message: {
      text: "This has been updated!"
    }
  } = Juvet.SlackAPI.Chat.update(%{token: token, channel: channel, text: text, ts: timestamp})
  """
  @spec update(map()) :: {:ok, map()} | {:error, map()}
  def update(options \\ %{}) do
    options = options |> transform_options

    SlackAPI.make_request("chat.update", options)
    |> SlackAPI.render_response()
  end

  defp encode_blocks(nil), do: nil
  defp encode_blocks(blocks), do: Poison.encode!(blocks)

  defp transform_options(options) do
    options
    |> Map.get_and_update(:blocks, &{&1, encode_blocks(&1)})
    |> elem(1)
    |> Enum.filter(fn {_key, value} -> !is_nil(value) end)
    |> Enum.into(%{})
  end
end
