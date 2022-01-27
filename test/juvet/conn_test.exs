defmodule Juvet.ConnTest do
  use ExUnit.Case, async: true

  describe "put_private/2" do
    setup do
      conn = %Plug.Conn{}

      [conn: conn]
    end

    test "adds value to the private juvet key in the conn", %{conn: conn} do
      conn = Juvet.Conn.put_private(conn, %{foo: :bar})

      assert conn.private[:juvet] == %{foo: :bar}
    end

    test "merges existing private juvet values", %{conn: conn} do
      conn = Plug.Conn.put_private(conn, :juvet, %{blah: "blah"})

      conn = Juvet.Conn.put_private(conn, %{foo: :bar})

      assert conn.private[:juvet] == %{blah: "blah", foo: :bar}
    end
  end
end
