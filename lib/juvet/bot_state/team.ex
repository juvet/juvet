defmodule Juvet.BotState.Team do
  @enforce_keys [:id]
  defstruct [:id, :name, users: []]

  alias Juvet.UserState

  def put_user(state, %{id: user_id} = user) do
    # TODO: Call new_user_callback \\ nil if it is a new user callback is specified
    case user(state, user_id) do
      nil ->
        new_user = struct(UserState, user)
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
