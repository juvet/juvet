defmodule Juvet.Middleware.NormalizeRequestParamsTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.NormalizeRequestParams
  alias Juvet.Router.Request

  describe "call/1" do
    setup do
      params = %{"payload" => %{"team" => %{"id" => "T12345"}, "user" => %{"id" => "U12345"}}}
      request = Request.new(%{params: params})

      [context: %{request: %{request | platform: :slack}}]
    end

    test "decodes the request parameters based on the request platform", %{context: context} do
      assert {:ok, %{request: %{params: %{team_id: team_id, user_id: user_id}}}} =
               NormalizeRequestParams.call(context)

      assert team_id == "T12345"
      assert user_id == "U12345"
    end

    test "does not normalize parameters if there is no request" do
      assert {:ok, context} = NormalizeRequestParams.call(%{})
      refute Map.get(context, :request)
    end
  end
end
