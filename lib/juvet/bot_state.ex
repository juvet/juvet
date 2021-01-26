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
