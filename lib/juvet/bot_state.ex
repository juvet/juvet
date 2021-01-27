defmodule Juvet.BotState do
  defstruct bot_supervisor: nil, platforms: []

  alias Juvet.PlatformState

  def put_platform(state, platform_name) do
    case platform(state, platform_name) do
      nil ->
        platforms = state.platforms
        new_platform = %PlatformState{name: platform_name}

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
        {platform, team} = PlatformState.put_team(platform, team)
        platforms = state.platforms
        index = Enum.find_index(platforms, &find(&1, platform_name))

        {%{
           state
           | platforms: List.replace_at(platforms, index, platform)
         }, platform, team}
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
