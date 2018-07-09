defmodule Juvet.Bot do
  @moduledoc """
  Bot is a macro interface for working with a bot that is connected to third-party
  services.

  ## Example
  ```
  defmodule MyBot do
    use Bot

    def handle_event(:slack, message = %{type: "message"}, state) do
      if message.text == "Hi" do
        send_message(:slack, "Hello to you too!", message.channel)
      end
      {:ok, state}
    end

    def handle_event(_, _, state), do: {:ok, state}
  end
  ```
  """

  defmacro __using__(_) do
    quote do
      @doc ~S"""
      Called when a platform is connected to this bot.

      Returns `{:ok, state}` where the `state` can be modified and placed back onto the
      process.
      """
      def handle_connect(_platform, state), do: {:ok, state}

      @doc ~S"""
      Called when a platform is disconnected from this bot.

      Returns `{:ok, state}` where the `state` can be modified and placed back onto the
      process.
      """
      def handle_disconnect(_platform, state), do: {:ok, state}

      @doc ~S"""
      Called when any event occurs on a platform for this bot. The `message` can be
      patterned matched so multiple events can be handled.

      Returns `{:ok, state}` where the `state` can be modified and placed back onto the
      process.
      """
      def handle_event(_platform, _message, state), do: {:ok, state}

      @doc ~S"""
      Sends a message via PubSub to the `platform` specified with the workspace `id`.
      """
      def send_message(platform, %{id: id} = state, message) do
        PubSub.publish(:"outgoing_#{platform}_message_#{id}", [
          :"outgoing_#{platform}_message",
          message
        ])

        :ok
      end

      defoverridable handle_connect: 2, handle_disconnect: 2, handle_event: 3
    end
  end
end
