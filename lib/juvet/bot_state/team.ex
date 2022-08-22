defmodule Juvet.BotState.Team do
  @moduledoc """
  Represents a team that is stored in the state for a `Juvet.Bot`.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          scopes: list(map()) | [] | nil,
          token: String.t(),
          url: String.t(),
          users: list(Juvet.BotState.User.t()) | []
        }
  @enforce_keys [:id]
  defstruct [:id, :name, :scopes, :token, :url, users: []]

  alias Juvet.BotState.User

  @spec from_auth(Access.t()) :: Juvet.BotState.Team.t()
  def from_auth(auth) do
    %Juvet.BotState.Team{
      id: get_in(auth, [:team, :id]),
      name: get_in(auth, [:team, :name]),
      token: get_in(auth, [:access_token]),
      scopes: get_in(auth, [:scope])
    }
  end

  @spec put_user(Juvet.BotState.Team.t(), map()) :: Juvet.BotState.Team.t()
  def put_user(team, %{id: user_id} = user) do
    case user(team, user_id) do
      nil ->
        new_user = struct(User, user)
        users = team.users

        {%{team | users: users ++ [new_user]}, new_user}

      existing_user ->
        new_user = Map.merge(existing_user, user)
        users = team.users
        index = Enum.find_index(users, &find(&1, existing_user.id))

        {%{team | users: List.replace_at(users, index, new_user)}, new_user}
    end
  end

  @spec has_user?(Juvet.BotState.Team.t(), String.t()) :: boolean()
  def has_user?(team, user_id) do
    Enum.any?(team.users, &find(&1, user_id))
  end

  @spec user(Juvet.BotState.Team.t(), String.t()) :: Juvet.BotState.User.t()
  def user(team, user_id) do
    case Enum.find(team.users, &find(&1, user_id)) do
      nil -> nil
      user -> user
    end
  end

  defp find(user, id), do: user.id == id
end
