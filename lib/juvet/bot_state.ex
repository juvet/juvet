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

  @spec get_messages(Juvet.BotState.t()) :: list(Juvet.BotState.Message.t())
  def get_messages(state) do
    Enum.flat_map(state.platforms, &Platform.get_messages(&1))
  end

  @spec put_message({Juvet.BotState.t(), Juvet.BotState.Platform.t()}, map()) ::
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

  @spec put_platform(Juvet.BotState.t(), String.t()) ::
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

  @spec put_user({Juvet.BotState.t(), Juvet.BotState.Platform.t()}, map()) ::
          {Juvet.BotState.t(), Juvet.BotState.Platform.t() | nil, map() | nil, map() | nil}
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

  @spec has_platform?(Juvet.BotState.t(), String.t()) :: boolean()
  def has_platform?(state, platform_name) do
    Enum.any?(state.platforms, &find(&1, platform_name))
  end

  @spec platform(Juvet.BotState.t(), String.t()) :: Juvet.BotState.Platform.t() | nil
  def platform(state, platform_name) do
    case Enum.find(state.platforms, &find(&1, platform_name)) do
      nil -> nil
      platform -> platform
    end
  end

  defp find(platform, name), do: platform.name == name
end
