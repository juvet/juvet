defmodule Juvet.Middleware.ParseRequestTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  describe "call/1" do
    setup do
      conn = request!(:post, "/slack/commands")

      [context: %{conn: conn}]
    end

    test "returns a request from the conn", %{context: context} do
      assert {:ok, ctx} = Juvet.Middleware.ParseRequest.call(context)
      assert ctx[:request].status == 200
    end
  end
end
