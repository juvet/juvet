defmodule Juvet.BotState.User do
  @moduledoc """
  Represents a `User` that is stored in the state for a `Juvet.Bot`.
  """

  @enforce_keys [:id]
  defstruct [:id, :name, :scopes, :token, :username]

  def from_auth(auth) do
    %Juvet.BotState.User{
      id: get_in(auth, [:authed_user, :id]),
      token: get_in(auth, [:authed_user, :access_token]),
      scopes: get_in(auth, [:authed_user, :scope])
    }
  end
end
