defmodule Juvet.SlackAPI.UsersTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, user: "USER1", token: "TOKEN"}
  end

  describe "SlackAPI.Users.info/1" do
    test "returns infomation about the user", %{user: user, token: token} do
      use_cassette "users/info/successful" do
        assert {:ok, %{} = response} = SlackAPI.Users.info(%{user: user, token: token})

        assert response[:user][:id]
      end
    end

    test "returns an error from an unsuccessful API call", %{
      user: user,
      token: token
    } do
      use_cassette "users/info/invalid_auth" do
        assert {:error, %{} = response} = SlackAPI.Users.info(%{user: user, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end
end
