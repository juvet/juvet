defmodule Juvet.BotState.Team do
  @moduledoc """
  Represents a team that is stored in the state for a `Juvet.Bot`.
  """

  @enforce_keys [:id]
  defstruct [:id, :name, :scopes, :token, :url, users: []]

  alias Juvet.BotState.User

  def from_auth(auth) do
    %Juvet.BotState.Team{
      id: get_in(auth, [:team, :id]),
      name: get_in(auth, [:team, :name]),
      token: get_in(auth, [:access_token]),
      scopes: get_in(auth, [:scope])
    }
  end

  def put_user(state, %{id: user_id} = user) do
    case user(state, user_id) do
      nil ->
        new_user = struct(User, user)
        users = state.users

        {%{state | users: users ++ [new_user]}, new_user}

      existing_user ->
        new_user = Map.merge(existing_user, user)
        users = state.users
        index = Enum.find_index(users, &find(&1, existing_user.id))

        {%{state | users: List.replace_at(users, index, new_user)}, new_user}
    end
  end

  def has_user?(state, user_id) do
    Enum.any?(state.users, &find(&1, user_id))
  end

  def user(state, user_id) do
    case Enum.find(state.users, &find(&1, user_id)) do
      nil -> nil
      user -> user
    end
  end

  defp find(user, id), do: user.id == id
end
