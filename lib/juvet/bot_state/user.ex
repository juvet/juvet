defmodule Juvet.BotState.User do
  @enforce_keys [:id]
  defstruct [:id, :name, :scopes, :token, :username]

  def from_ueberauth(auth) do
    %Juvet.BotState.User{
      id: get_in(auth, [:extra, :raw_info, :user, :id]),
      name: get_in(auth, [:info, :name]),
      username: get_in(auth, [:info, :nickname]),
      token: get_in(auth, [:credentials, :token]),
      scopes: get_in(auth, [:credentials, :scopes])
    }
  end
end
