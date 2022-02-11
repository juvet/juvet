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
    options = options |> transform_options

    SlackAPI.make_request("chat.postMessage", options)
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
