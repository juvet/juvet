defmodule Juvet.CacheBodyReaderTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  alias Juvet.CacheBodyReader

  describe "read_body/2" do
    setup do
      [conn: request!(:post, "/blah")]
    end

    test "puts the raw body into the juvet shared library", %{conn: conn} do
      {:ok, _body, conn} = CacheBodyReader.read_body(conn, [])

      assert conn.private[:juvet][:raw_body]
    end

    test "merges with any existing entries in the juvet shared library", %{
      conn: conn
    } do
      conn = conn |> Plug.Conn.put_private(:juvet, %{blah: "blah"})

      {:ok, _body, conn} = CacheBodyReader.read_body(conn, [])

      assert conn.private[:juvet][:blah] == "blah"
      assert conn.private[:juvet][:raw_body]
    end
  end
end
