defmodule Juvet.BotState.Platform do
  @enforce_keys [:name]
  defstruct [:name, teams: []]

  alias Juvet.TeamState

  def put_team(state, %{id: team_id} = team) do
    # TODO: Call new_team_callback \\ nil if it is a new team and the callback is specified
    case team(state, team_id) do
      nil ->
        new_team = struct(TeamState, team)
        teams = state.teams

        {%{state | teams: teams ++ [new_team]}, new_team}

      existing_team ->
        new_team = Map.merge(existing_team, team)
        teams = state.teams
        index = Enum.find_index(teams, &find(&1, existing_team.id))

        {%{state | teams: List.replace_at(teams, index, new_team)}, new_team}
    end
  end

  def has_team?(state, team_id) do
    Enum.any?(state.teams, &find(&1, team_id))
  end

  def team(state, team_id) do
    case Enum.find(state.teams, &find(&1, team_id)) do
      nil -> nil
      team -> team
    end
  end

  defp find(team, id), do: team.id == id
end
