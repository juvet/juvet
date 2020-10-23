defmodule Juvet.Bot do
  @moduledoc """
  Bot is a macro interface for working with a bot that is connected to third-party
  services.

  ## Example
  ```
  defmodule MyBot do
    use Bot
  end
  ```
  """

  defmacro __using__(_) do
    quote do
      use GenServer

      # Client API

      def start_link(state, options \\ []) do
        GenServer.start_link(__MODULE__, state, options)
      end

      def get_state(pid) do
      end

      # Server Callbacks

      def init(state) do
        {:ok, state}
      end
    end
  end
end
