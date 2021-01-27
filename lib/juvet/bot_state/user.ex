defmodule Juvet.BotState.User do
  @enforce_keys [:id]
  defstruct [:id, :name, :scopes, :token, :username]
end
