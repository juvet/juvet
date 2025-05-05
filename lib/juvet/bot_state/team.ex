defmodule Juvet.BotState.Team do
  @moduledoc """
  Represents a team that is stored in the state for a `Juvet.Bot`.
  """

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          scopes: list(map()),
          token: String.t(),
          url: String.t(),
          users: list(Juvet.BotState.User.t())
        }
  @enforce_keys [:id]
  defstruct [:id, :name, :scopes, :token, :url, users: []]

  alias Juvet.BotState.User

  @doc """
  Populate a new `Juvet.BotState.Team` from an authorization hash.
  """
  def from_auth(auth) do
    %__MODULE__{
      id: get_in(auth, [:team, :id]),
      name: get_in(auth, [:team, :name]),
      token: get_in(auth, [:access_token]),
      scopes: get_in(auth, [:scope])
    }
  end

  @doc """
  Puts a new `Juvet.BotState.User` into the `Juvet.BotState.Team` and returns a new `Juvet.BotState.Team` with
  the new user.
  """
  @spec put_user(Juvet.BotState.Team.t(), map()) ::
          {Juvet.BotState.Team.t(), Juvet.BotState.User.t()}
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

  @doc """
  Returns a boolean to indiciated if the provided `Juvet.BotState.Team` contains a `Juvet.BotState.User`
  with the specified user id..
  """
  @spec has_user?(Juvet.BotState.Team.t(), String.t()) :: boolean()
  def has_user?(team, user_id) do
    Enum.any?(team.users, &find(&1, user_id))
  end

  @doc """
  Returns a `Juvet.BotState.User` with the specified user_id from the `Juvet.BotState.Team.`
  """
  @spec user(Juvet.BotState.Team.t(), String.t()) :: Juvet.BotState.User.t() | nil
  def user(team, user_id) do
    case Enum.find(team.users, &find(&1, user_id)) do
      nil -> nil
      user -> user
    end
  end

  defp find(user, id), do: user.id == id
end
