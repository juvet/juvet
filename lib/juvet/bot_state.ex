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
    Enum.any?(state.platforms, fn p -> Kernel.elem(p, 0) == platform end)
  end
end
