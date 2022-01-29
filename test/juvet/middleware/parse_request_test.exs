defmodule Juvet.Middleware.ParseRequestTest do
  use ExUnit.Case, async: true

  alias Juvet.Middleware.ParseRequest

  describe "call/1" do
    setup do
      conn = %Plug.Conn{
        method: "POST",
        params: %{foo: :bar},
        request_path: "/slack/commands",
        status: 200
      }

      [context: %{conn: conn}]
    end

    test "returns a request from the conn", %{context: context} do
      assert {:ok, ctx} = ParseRequest.call(context)
      assert ctx[:request].status == 200
    end
  end
end
