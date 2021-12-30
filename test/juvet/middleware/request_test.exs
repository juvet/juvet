defmodule Juvet.Middleware.RequestTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  describe "new/1" do
    setup do
      conn = request!(:post, "/slack/commands", %{foo: :bar})

      [conn: conn]
    end

    test "returns a structure from the conn", %{conn: conn} do
      request = Juvet.Middleware.Request.new(conn)

      assert request.headers == [
               {"content-type", "multipart/mixed; boundary=plug_conn_test"}
             ]

      assert request.host == "www.example.com"
      assert request.method == "POST"
      assert request.params == %{"foo" => :bar}
      assert request.path == "/slack/commands"
      assert request.port == 80
      assert request.query_string == ""
      assert request.scheme == :http
      assert request.status == 200
    end
  end
end
