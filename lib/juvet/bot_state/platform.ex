defmodule Juvet.BotState.Platform do
  @moduledoc """
  Represents a platform that is stored in the state for a `Juvet.Bot`.
  """

  @type t :: %__MODULE__{
          name: String.t(),
          messages: list(map()),
          teams: list(Juvet.BotState.Team.t())
        }
  @enforce_keys [:name]
  defstruct [:name, messages: [], teams: []]

  alias Juvet.BotState.Team

  @spec get_messages(Juvet.BotState.Platform.t()) :: list(map())
  def get_messages(platform) do
    platform.messages
  end

  @spec put_message(Juvet.BotState.Platform.t(), map()) :: {Juvet.BotState.Platform.t(), map}
  def put_message(platform, message) do
    messages = platform.messages

    {%{platform | messages: messages ++ [message]}, message}
  end

  @spec put_team(Juvet.BotState.Platform.t(), map()) :: {Juvet.BotState.Platform.t(), map()}
  def put_team(platform, %{id: team_id} = team) do
    case team(platform, team_id) do
      nil ->
        new_team = struct(Team, team)
        teams = platform.teams

        {%{platform | teams: teams ++ [new_team]}, new_team}

      existing_team ->
        new_team = Map.merge(existing_team, team)
        teams = platform.teams
        index = Enum.find_index(teams, &find(&1, existing_team.id))

        {%{platform | teams: List.replace_at(teams, index, new_team)}, new_team}
    end
  end

  @spec has_team?(Juvet.BotState.Platform.t(), String.t()) :: boolean()
  def has_team?(platform, team_id) do
    Enum.any?(platform.teams, &find(&1, team_id))
  end

  @spec team(Juvet.BotState.Platform.t(), String.t()) :: Juvet.BotState.Team.t() | nil
  def team(platform, team_id) do
    case Enum.find(platform.teams, &find(&1, team_id)) do
      nil -> nil
      team -> team
    end
  end

  defp find(team, id), do: team.id == id
end
