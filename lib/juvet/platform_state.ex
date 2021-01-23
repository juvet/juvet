defmodule Juvet.PlatformState do
  defstruct teams: []

  def add_team(state, team) do
    case has_team?(state, team) do
      false ->
        teams = state.teams
        %{state | teams: teams ++ [{team, %Juvet.TeamState{}}]}

      true ->
        state
    end
  end

  def has_team?(state, team) do
    Enum.any?(state.teams, &find(&1, team))
  end

  def team(state, team) do
    case Enum.find(state.teams, &find(&1, team)) do
      {_team, team_state} -> team_state
      nil -> nil
    end
  end

  defp find(team, id), do: Kernel.elem(team, 0) == id
end
