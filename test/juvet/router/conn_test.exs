defmodule Juvet.Router.ConnTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  alias Juvet.Router.Conn

  describe "send_resp/1" do
    setup do
      context =
        Map.new(
          conn: build_conn(:post, "/slack/commands"),
          response: %{status: 200, body: ""}
        )

      [context: context]
    end

    test "sends a response through the conn in the context", %{context: context} do
      conn = Conn.send_resp(context)

      assert conn.status == 200
    end

    test "halts the response after sending by default", %{context: context} do
      conn = Conn.send_resp(context)

      assert conn.halted
    end

    test "can optionally not halt the response", %{context: context} do
      conn = Conn.send_resp(context, halt: false)

      refute conn.halted
    end
  end
end
