defmodule Juvet.SlackAPI.ConversationsTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, users: ["USER1"], token: "TOKEN"}
  end

  describe "SlackAPI.Conversations.open/1" do
    test "returns the channel id", %{users: users, token: token} do
      use_cassette "conversations/open/successful" do
        assert {:ok, response} = SlackAPI.Conversations.open(%{users: users, token: token})

        assert response[:channel][:id]
      end
    end

    test "returns an error from an unsuccessful API call", %{
      users: users,
      token: token
    } do
      use_cassette "conversations/open/invalid_auth" do
        assert {:error, response} = SlackAPI.Conversations.open(%{users: users, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end
end
