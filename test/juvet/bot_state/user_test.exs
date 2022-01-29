defmodule Juvet.BotState.UserTest do
  use ExUnit.Case

  alias Juvet.BotState.User

  describe "from_auth/1" do
    setup do
      auth = %{
        access_token: "SLACK_TOKEN",
        authed_user: %{
          id: "U12345",
          access_token: "USER_TOKEN",
          scope: "identify"
        },
        bot_user_id: "UBOT",
        scope: "users:read",
        team: %{id: "T1234", name: "Zeppelin"},
        token_type: "bot"
      }

      {:ok, auth: auth}
    end

    test "returns a struct based on the auth response data", %{auth: auth} do
      user = User.from_auth(auth)

      assert user.id == "U12345"
      assert user.token == "USER_TOKEN"
      assert user.scopes == "identify"
    end
  end
end
