defmodule Juvet.BotState do
  @moduledoc """
  A structre that represents what is stored for a given `Juvet.Bot` within the process.
  """

  defstruct bot_supervisor: nil, platforms: []

  alias Juvet.BotState.{Platform, Team}

  def get_messages(state) do
    Enum.flat_map(state.platforms, &Platform.get_messages(&1))
  end

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

  def has_platform?(state, platform_name) do
    Enum.any?(state.platforms, &find(&1, platform_name))
  end

  def platform(state, platform_name) do
    case Enum.find(state.platforms, &find(&1, platform_name)) do
      nil -> nil
      platform -> platform
    end
  end

  defp find(platform, name), do: platform.name == name
end
