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
      use Juvet.ReceiverTarget

      defmodule Platform do
        defstruct platform: nil, id: nil, messages: []

        def add_message(platform, message) do
          messages = platform.messages

          %{platform | messages: messages ++ [message]}
        end
      end

      defmodule State do
        defstruct bot_supervisor: nil, platforms: []

        def add_platform_message(state, platform, message) do
          platforms =
            Enum.map(state.platforms, fn
              %Platform{platform: platform} = p ->
                Platform.add_message(p, message)

              p ->
                p
            end)

          %{state | platforms: platforms}
        end

        def get_platform_messages(state) do
          Enum.flat_map(state.platforms, fn platform -> platform.messages end)
        end
      end

      # Client API

      def start_link(state, options \\ []) do
        GenServer.start_link(__MODULE__, state, options)
      end

      def add_receiver(pid, type, parameters) do
        GenServer.call(pid, {:add_receiver, type, parameters})
      end

      def connect(pid, :slack, parameters = %{team_id: _team_id}) do
        GenServer.cast(pid, {:connect, :slack, parameters})
      end

      def get_messages(pid), do: GenServer.call(pid, :get_messages)

      def get_state(pid), do: GenServer.call(pid, :get_state)

      # Server Callbacks

      def init(state) do
        {:ok, struct(State, state)}
      end

      def handle_call({:add_receiver, type, parameters}, _from, state) do
        result =
          generate_receiver(type).start(
            state.bot_supervisor,
            self(),
            parameters
          )

        {:reply, result, state}
      end

      def handle_call(:get_messages, _from, state) do
        {:reply, State.get_platform_messages(state), state}
      end

      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

      def handle_cast(
            {:connect, :slack, %{team_id: team_id}},
            %{platforms: platforms} = state
          ) do
        state = %{
          state
          | platforms: [%Platform{platform: :slack, id: team_id} | platforms]
        }

        {:noreply, state}
      end

      def handle_info({:connected, platform, message}, state) do
        {:noreply, State.add_platform_message(state, platform, message)}
      end

      def handle_info({:new_message, platform, message}, state) do
        {:noreply, State.add_platform_message(state, platform, message)}
      end
    end
  end
end
