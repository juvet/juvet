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
      use GenServer
      use Juvet.ReceiverTarget

      # Client API

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
      def connect(pid, :slack, parameters = %{team_id: _team_id}) do
        GenServer.cast(pid, {:connect, :slack, parameters})
      end

      @doc """
      Returns a List of messages from the bot for all the platforms.

      ## Example

      ```
      messages = MyBot.get_messages(bot)
      ```
      """
      def get_messages(pid), do: GenServer.call(pid, :get_messages)

      @doc """
      Returns the current state for the bot.

      ## Example

      ```
      state = MyBot.get_state(bot)
      ```
      """
      def get_state(pid), do: GenServer.call(pid, :get_state)

      def user_install(pid, platform, parameters) do
        GenServer.call(pid, {:user_install, platform, parameters})
      end

      # Server Callbacks

      @doc false
      def init(state) do
        {:ok, struct(Juvet.BotState, state)}
      end

      @doc false
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
      def handle_call(:get_messages, _from, state) do
        {:reply, Juvet.BotState.get_messages(state), state}
      end

      @doc false
      def handle_call(:get_state, _from, state) do
        {:reply, state, state}
      end

      @doc false
      def handle_call({:user_install, platform, parameters}, _from, state) do
        # TODO: Juvet.BotState.Team.from_ueberauth(parameters)
        team = %{
          id: parameters.credentials.other.team_id,
          name: parameters.credentials.other.team,
          url: parameters.credentials.other.team_url,
          # TODO: is this supposed to be the team token?
          token: parameters.credentials.token,
          # TODO: are these the team or user scopes?
          scopes: parameters.credentials.scopes
        }

        # TODO: Juvet.BotState.User.from_ueberauth(parameters)
        user = %{
          id: parameters.extra.raw_info.user.id,
          username: parameters.info.nickname,
          name: parameters.info.name,
          # TODO: is this supposed to be the user token?
          token: parameters.credentials.token,
          # TODO: are these the team or user scopes?
          scopes: parameters.credentials.scopes
        }

        {state, _platform, _team, user} =
          Juvet.BotState.put_platform(state, platform)
          |> Juvet.BotState.put_team(team)
          |> Juvet.BotState.put_user(user)

        {:reply, {:ok, user}, state}
      end

      @doc false
      def handle_cast({:connect, :slack, parameters}, state) do
        {state, _platform, _message} =
          Juvet.BotState.put_platform(state, :slack)
          |> Juvet.BotState.put_message(parameters)

        {:noreply, state}
      end

      @doc false
      def handle_info({:connected, platform, message}, state) do
        {:noreply, put_message(state, platform, message)}
      end

      @doc false
      def handle_info({:new_message, platform, message}, state) do
        {:noreply, put_message(state, platform, message)}
      end

      @doc false
      defp put_message(state, platform_name, message) do
        platform = %Juvet.BotState.Platform{name: platform_name}

        {state, _platform, _message} =
          Juvet.BotState.put_message({state, platform}, message)

        state
      end
    end
  end
end
