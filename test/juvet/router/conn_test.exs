defmodule Juvet.Router.ConnTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  alias Juvet.Router.Conn

  describe "put_private/2" do
    setup do
      conn = %Plug.Conn{}

      [conn: conn]
    end

    test "adds value to the private juvet key in the conn", %{conn: conn} do
      conn = Conn.put_private(conn, %{foo: :bar})

      assert conn.private[:juvet] == %{foo: :bar}
    end

    test "merges existing private juvet values", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :juvet, %{blah: "blah"})

      conn = Conn.put_private(conn, %{foo: :bar})

      assert conn.private[:juvet] == %{blah: "blah", foo: :bar}
    end
  end

  describe "send_resp/1" do
    setup do
      context =
        Map.new(
          conn: build_conn(:post, "/slack/commands"),
          response: Juvet.Router.Response.new()
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
