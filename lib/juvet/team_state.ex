defmodule Juvet.TeamState do
  @enforce_keys [:id]
  defstruct [:id, users: []]

  def add_user(state, user, attributes \\ []) do
    case has_user?(state, user) do
      false ->
        users = state.users

        %{
          state
          | users: users ++ [{user, Kernel.struct(Juvet.UserState, attributes)}]
        }

      true ->
        state
    end
  end

  def has_user?(state, user) do
    Enum.any?(state.users, &find(&1, user))
  end

  def user(state, user) do
    case Enum.find(state.users, &find(&1, user)) do
      {_user, user_state} -> user_state
      nil -> nil
    end
  end

  defp find(user, id), do: Kernel.elem(user, 0) == id
end
