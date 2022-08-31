defmodule Juvet.BotState do
  @moduledoc """
  A structre that represents what is stored for a given `Juvet.Bot` within the process.
  """

  @type t :: %__MODULE__{
          bot_supervisor: pid(),
          platforms: list(Juvet.BotState.Platform.t())
        }
  defstruct bot_supervisor: nil, platforms: []

  alias Juvet.BotState.{Platform, Team}

  @doc """
  Retrieves a list of messages from the `Juvet.BotState`.
  """
  @spec get_messages(Juvet.BotState.t()) :: list(map())
  def get_messages(state) do
    Enum.flat_map(state.platforms, &Platform.get_messages(&1))
  end

  @doc """
  Puts a new message into the `Juvet.BotState` for the specified platform and returns a new `Juvet.BotState` with
  the new message.
  """
  @spec put_message({Juvet.BotState.t(), Juvet.BotState.Platform.t() | nil}, map()) ::
          {Juvet.BotState.t(), Juvet.BotState.Platform.t() | nil, map() | nil}
  def put_message({state, %{name: platform_name}}, message) do
    case platform(state, platform_name) do
      nil ->
        {state, nil, nil}

      platform ->
        {platform, message} = Platform.put_message(platform, message)

        platforms = state.platforms
        index = Enum.find_index(platforms, &find(&1, platform_name))

        {%{
           state
           | platforms: List.replace_at(platforms, index, platform)
         }, platform, message}
    end
  end

  @doc """
  Puts a new platform into the `Juvet.BotState` and returns a new `Juvet.BotState` with the new platform.
  """
  @spec put_platform(Juvet.BotState.t(), String.t() | atom()) ::
          {Juvet.BotState.t(), Juvet.BotState.Platform.t()}
  def put_platform(state, platform_name) do
    case platform(state, platform_name) do
      nil ->
        platforms = state.platforms
        new_platform = %Platform{name: platform_name}

        {%{state | platforms: platforms ++ [new_platform]}, new_platform}

      existing_platform ->
        {state, existing_platform}
    end
  end

  @doc """
  Puts a new team into the `Juvet.BotState` for the specified platform and returns a new `Juvet.BotState` with
  the new team.
  """
  @spec put_team({Juvet.BotState.t(), Juvet.BotState.Platform.t()}, map()) ::
          {Juvet.BotState.t(), Juvet.BotState.Platform.t() | nil, map() | nil}
  def put_team({state, %{name: platform_name}}, team) do
    case platform(state, platform_name) do
      nil ->
        {state, nil, nil}

      platform ->
        {platform, team} = Platform.put_team(platform, team)

        platforms = state.platforms
        index = Enum.find_index(platforms, &find(&1, platform_name))

        {%{
           state
           | platforms: List.replace_at(platforms, index, platform)
         }, platform, team}
    end
  end

  @doc """
  Puts a new user into the `Juvet.BotState` for the specified platform and team and returns a new `Juvet.BotState` with
  the new user.
  """
  @spec put_user(
          {Juvet.BotState.t(), Juvet.BotState.Platform.t(), Juvet.BotState.User.t()},
          map()
        ) ::
          {Juvet.BotState.t(), Juvet.BotState.Platform.t() | nil, Juvet.BotState.User.t() | nil,
           map() | nil}
  def put_user({state, platform, team}, user) do
    case put_team({state, platform}, team) do
      {state, nil, nil} ->
        {state, nil, nil, nil}

      {state, platform, team} ->
        case Team.put_user(team, user) do
          {team, user} ->
            teams = platform.teams
            index = Enum.find_index(teams, fn t -> t.id == team.id end)

            platform = %{
              platform
              | teams: List.replace_at(teams, index, team)
            }

            platforms = state.platforms
            index = Enum.find_index(platforms, &find(&1, platform.name))

            {%{state | platforms: List.replace_at(platforms, index, platform)}, platform, team,
             user}
        end
    end
  end

  @doc """
  Returns a boolean to indiciated if the provided `Juvet.BotState` contains the specified pattern,.
  """
  @spec has_platform?(Juvet.BotState.t(), String.t()) :: boolean()
  def has_platform?(state, platform_name) do
    Enum.any?(state.platforms, &find(&1, platform_name))
  end

  @doc """
  Returns a `Juvet.BotState.Platform` with the specified name from the `Juvet.BotState.`
  """
  @spec platform(Juvet.BotState.t(), String.t()) :: Juvet.BotState.Platform.t() | nil
  def platform(state, platform_name) do
    case Enum.find(state.platforms, &find(&1, platform_name)) do
      nil -> nil
      platform -> platform
    end
  end

  defp find(platform, name), do: platform.name == name
end
