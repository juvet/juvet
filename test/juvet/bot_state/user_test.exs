defmodule Juvet.BotState.UserTest do
  use ExUnit.Case

  describe "Juvet.BotState.User.from_ueberauth/1" do
    setup do
      auth = %{
        credentials: %{
          token: "SLACK_TOKEN",
          scopes: ["identify"]
        },
        extra: %{
          raw_info: %{
            user: %{
              id: "U12345"
            }
          }
        },
        info: %{
          name: "Jimmy Page",
          nickname: "jimmy"
        }
      }

      {:ok, auth: auth}
    end

    test "returns a struct based on the ueberauth data", %{auth: auth} do
      user = Juvet.BotState.User.from_ueberauth(auth)

      assert user.id == "U12345"
      assert user.name == "Jimmy Page"
      assert user.username == "jimmy"
      assert user.token == "SLACK_TOKEN"
      assert user.scopes == ["identify"]
    end
  end
end
