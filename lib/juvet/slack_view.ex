defmodule Juvet.SlackView do
  @moduledoc """
  Helper functions for a module handling a response for Slack.
  """

  alias Juvet.SlackAPI

  defmacro __using__(_opts) do
    quote do
      unquote(prelude())
    end
  end

  defp prelude do
    quote do
      import unquote(__MODULE__)

      alias Juvet.SlackAPI
    end
  end

  def create_or_update_slack_message(message, message_id \\ nil)

  def create_or_update_slack_message(message, nil), do: create_slack_message(message)

  def create_or_update_slack_message(message, message_id),
    do: update_slack_message(message, message_id)

  def create_slack_message(%{channel: _, token: _, blocks: _} = message),
    do: message |> SlackAPI.Chat.post_message()

  def update_slack_message(%{channel: _, token: _, blocks: _} = message, message_id),
    do: message |> Map.merge(%{ts: message_id}) |> SlackAPI.Chat.update()
end
