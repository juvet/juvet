defmodule Juvet.BotState do
  defstruct bot_supervisor: nil, platforms: []

  alias Juvet.PlatformState

  def put_platform(state, platform) do
    case platform(state, platform) do
      nil ->
        platforms = state.platforms
        new_platform = %PlatformState{name: platform}

        {%{state | platforms: platforms ++ [new_platform]}, new_platform}

      existing_platform ->
        {state, existing_platform}
    end
  end

  def has_platform?(state, platform) do
    Enum.any?(state.platforms, &find(&1, platform))
  end

  def platform(state, platform) do
    case Enum.find(state.platforms, &find(&1, platform)) do
      nil -> nil
      p -> p
    end
  end

  defp find(platform, name), do: platform.name == name
end
