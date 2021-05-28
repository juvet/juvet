defmodule Juvet.SlackAPI.ChatTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias Juvet.SlackAPI

  setup_all do
    HTTPoison.start()
  end

  setup do
    {:ok, channel: "CHANNEL1", text: "Hello from Juvet", token: "TOKEN"}
  end

  describe "SlackAPI.Chat.post_message/1" do
    test "returns the message", %{channel: channel, text: text, token: token} do
      use_cassette "chat/postMessage/successful" do
        assert {:ok, response} =
                 SlackAPI.Chat.post_message(%{
                   channel: channel,
                   text: text,
                   token: token
                 })

        assert response[:message][:text] == "Hello from Juvet"
      end
    end

    test "returns an error from an unsuccessful API call", %{
      channel: channel,
      text: text,
      token: token
    } do
      use_cassette "chat/postMessage/invalid_auth" do
        assert {:error, response} =
                 SlackAPI.Chat.post_message(%{
                   channel: channel,
                   text: text,
                   token: token
                 })

        assert response[:error] == "invalid_auth"
      end
    end
  end
end
