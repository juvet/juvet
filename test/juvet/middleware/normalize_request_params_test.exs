defmodule Juvet.Middleware.NormalizeRequestParamsTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.NormalizeRequestParams
  alias Juvet.Router.Request

  describe "call/1 for a slack payload request" do
    setup do
      params = %{
        "payload" => %{
          "channel" => %{"id" => "C12345"},
          "team" => %{"id" => "T12345"},
          "user" => %{"id" => "U12345"}
        }
      }

      request = Request.new(%{params: params})

      [context: %{request: %{request | platform: :slack}}]
    end

    test "decodes the request parameters", %{context: context} do
      assert {:ok,
              %{request: %{params: %{channel_id: channel_id, team_id: team_id, user_id: user_id}}}} =
               NormalizeRequestParams.call(context)

      assert channel_id == "C12345"
      assert team_id == "T12345"
      assert user_id == "U12345"
    end
  end

  describe "call/1 for a slack command request" do
    setup do
      params = %{
        "channel_id" => "C12345",
        "team_id" => "T12345",
        "user_id" => "U12345"
      }

      request = Request.new(%{params: params})

      [context: %{request: %{request | platform: :slack}}]
    end

    test "decodes the request parameters", %{context: context} do
      assert {:ok,
              %{request: %{params: %{channel_id: channel_id, team_id: team_id, user_id: user_id}}}} =
               NormalizeRequestParams.call(context)

      assert channel_id == "C12345"
      assert team_id == "T12345"
      assert user_id == "U12345"
    end
  end

  describe "call/1 for no request" do
    test "does not normalize parameters" do
      assert {:ok, context} = NormalizeRequestParams.call(%{})
      refute Map.get(context, :request)
    end
  end
end
