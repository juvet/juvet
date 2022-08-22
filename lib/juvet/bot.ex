defmodule Juvet.Bot do
  @moduledoc """
  Bot is a macro interface for working with a bot that is connected to chat services.

  ## Example
  ```
  defmodule MyBot do
    use Juvet.Bot
  end
  ```
  """

  defmacro __using__(_) do
    quote do
      unquote(prelude())
      unquote(client())
      unquote(server())
    end
  end

  defp prelude do
    quote do
      use GenServer
      use Juvet.ReceiverTarget

      alias Juvet.BotState
      alias Juvet.BotState.{Platform, Team, User}
    end
  end

  # Client API
  defp client do
    quote do
      @doc """
      Starts a `Juvet.Bot` process linked to the current process.

      ## Options

      * `:bot_supervisor` - The `pid` of the supervisor that this bot process belongs to
      """
      def start_link(state, options \\ []) do
        GenServer.start_link(__MODULE__, state, options)
      end

      @doc """
      Adds a receiver to this bot which adds another source of messages
      for this bot to receive messages from.

      The receiver is another process and this function returns the pid
      of the new receiver.

      ## Example

      ```
      {:ok, pid} = MyBot.add_receiver(bot, :slack_rtm, %{
        token: "MY_TOKEN"
      })
      ```
      """
      @spec add_receiver(pid(), atom(), map()) :: {:ok, pid()}
      def add_receiver(pid, type, parameters) do
        GenServer.call(pid, {:add_receiver, type, parameters})
      end

      @doc """
      Adds a Slack platform to the bot state

      ## Example

      ```
      MyBot.connect(bot, :slack, %{token: "MY_TOKEN"})
      ```
      """
      @spec connect(pid(), atom(), map()) :: :ok
      def connect(pid, :slack, %{team_id: _team_id} = parameters) do
        GenServer.cast(pid, {:connect, :slack, parameters})
      end

      @doc """
      Returns a List of messages from the bot for all the platforms.

      ## Example

      ```
      messages = MyBot.get_messages(bot)
      ```
      """
      @spec get_messages(pid()) :: list(map())
      def get_messages(pid), do: GenServer.call(pid, :get_messages)

      @doc """
      Returns the current state for the bot.

      ## Example

      ```
      state = MyBot.get_state(bot)
      ```
      """
      @spec get_state(pid()) :: Juvet.BotState.t()
      def get_state(pid), do: GenServer.call(pid, :get_state)

      @spec user_install(pid(), atom(), keyword()) ::
              {:ok, Juvet.BotState.User.t(), Juvet.BotState.Team.t()}
      def user_install(pid, platform, parameters) do
        GenServer.call(pid, {:user_install, platform, parameters})
      end
    end
  end

  # Server Callbacks
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity
  defp server do
    quote do
      @doc false
      @impl true
      def init(state) do
        {:ok, struct(BotState, state)}
      end

      @doc false
      @impl true
      def handle_call({:add_receiver, type, parameters}, _from, state) do
        result =
          generate_receiver(type).start(
            state.bot_supervisor,
            self(),
            parameters
          )

        {:reply, result, state}
      end

      @doc false
      @impl true
      def handle_call(:get_messages, _from, state) do
        {:reply, BotState.get_messages(state), state}
      end

      @doc false
      @impl true
      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

      @doc false
      @impl true
      def handle_call({:user_install, platform, parameters}, _from, state) do
        team = Map.from_struct(Team.from_auth(parameters))
        user = Map.from_struct(User.from_auth(parameters))

        {state, _platform, team, user} =
          BotState.put_platform(state, platform)
          |> BotState.put_team(team)
          |> BotState.put_user(user)

        {:reply, {:ok, user, team}, state}
      end

      @doc false
      @impl true
      def handle_cast({:connect, :slack, parameters}, state) do
        {state, _platform, _message} =
          BotState.put_platform(state, :slack)
          |> BotState.put_message(parameters)

        {:noreply, state}
      end

      @doc false
      @impl true
      def handle_info({:connected, platform, message}, state) do
        {:noreply, put_message(state, platform, message)}
      end

      @doc false
      @impl true
      def handle_info({:new_message, platform, message}, state) do
        {:noreply, put_message(state, platform, message)}
      end

      defp put_message(state, platform_name, message) do
        platform = %Platform{name: platform_name}

        {state, _platform, _message} = BotState.put_message({state, platform}, message)

        state
      end
    end
  end
end
