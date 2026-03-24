defmodule Juvet.SlackAPI.ConversationsTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, channel: "CHANNEL1", users: ["USER1"], token: "TOKEN"}
  end

  describe "history/1" do
    test "returns the messages for the channel specified", %{channel: channel, token: token} do
      use_cassette "conversations/history/successful" do
        assert {:ok, response} = SlackAPI.Conversations.history(%{channel: channel, token: token})

        assert Enum.count(response[:messages]) > 0
      end
    end

    test "returns an error from an unsuccessful API call", %{
      channel: channel,
      token: token
    } do
      use_cassette "conversations/history/invalid_auth" do
        assert {:error, response} =
                 SlackAPI.Conversations.history(%{channel: channel, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end

  describe "info/1" do
    test "returns the channel details for the channel specified", %{channel: channel, token: token} do
      use_cassette "conversations/info/successful" do
        assert {:ok, response} = SlackAPI.Conversations.info(%{channel: channel, token: token})

        assert response[:channel][:id] == "CHANNEL1"
      end
    end

    test "returns an error from an unsuccessful API call", %{
      channel: channel,
      token: token
    } do
      use_cassette "conversations/info/invalid_auth" do
        assert {:error, response} =
                 SlackAPI.Conversations.info(%{channel: channel, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end

  describe "list/1" do
    test "returns the channels", %{token: token} do
      use_cassette "conversations/list/successful" do
        assert {:ok, response} = SlackAPI.Conversations.list(%{token: token})

        assert Enum.count(response[:channels]) > 0
      end
    end

    test "returns an error from an unsuccessful API call", %{token: token} do
      use_cassette "conversations/list/invalid_auth" do
        assert {:error, response} = SlackAPI.Conversations.list(%{token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end

  describe "mark/1" do
    test "returns a successful response", %{channel: channel, token: token} do
      use_cassette "conversations/mark/successful" do
        assert {:ok, _response} =
                 SlackAPI.Conversations.mark(%{channel: channel, ts: "1234567890.123456", token: token})
      end
    end

    test "returns an error from an unsuccessful API call", %{
      channel: channel,
      token: token
    } do
      use_cassette "conversations/mark/invalid_auth" do
        assert {:error, response} =
                 SlackAPI.Conversations.mark(%{channel: channel, ts: "1234567890.123456", token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end

  describe "members/1" do
    test "returns the users for the channel specified", %{channel: channel, token: token} do
      use_cassette "conversations/members/successful" do
        assert {:ok, response} = SlackAPI.Conversations.members(%{channel: channel, token: token})

        assert Enum.count(response[:members]) > 0
      end
    end

    test "returns an error from an unsuccessful API call", %{
      channel: channel,
      token: token
    } do
      use_cassette "conversations/members/invalid_auth" do
        assert {:error, response} =
                 SlackAPI.Conversations.members(%{channel: channel, token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end

  describe "replies/1" do
    test "returns the messages for the thread specified", %{channel: channel, token: token} do
      use_cassette "conversations/replies/successful" do
        assert {:ok, response} =
                 SlackAPI.Conversations.replies(%{channel: channel, ts: "1234567890.123456", token: token})

        assert Enum.count(response[:messages]) > 0
      end
    end

    test "returns an error from an unsuccessful API call", %{
      channel: channel,
      token: token
    } do
      use_cassette "conversations/replies/invalid_auth" do
        assert {:error, response} =
                 SlackAPI.Conversations.replies(%{channel: channel, ts: "1234567890.123456", token: token})

        assert response[:error] == "invalid_auth"
      end
    end
  end

  describe "open/1" do
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
