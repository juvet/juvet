defmodule Juvet.BotState do
  defstruct bot_supervisor: nil, platforms: []

  alias Juvet.PlatformState

  def add_platform(state, platform) do
    case has_platform?(state, platform) do
      false ->
        platforms = state.platforms
        %{state | platforms: platforms ++ [{platform, %PlatformState{}}]}

      true ->
        state
    end
  end

  def has_platform?(state, platform) do
    Enum.any?(state.platforms, &find(&1, platform))
  end

  def platform(state, platform) do
    case Enum.find(state.platforms, &find(&1, platform)) do
      {_platform, platform_state} -> platform_state
      nil -> nil
    end
  end

  defp find(platform, name), do: Kernel.elem(platform, 0) == name
end
