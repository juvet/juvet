defmodule Juvet.Router.RequestTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  setup_all do
    conn = request!(:post, "/slack/commands", %{foo: :bar})

    [conn: conn]
  end

  describe "new/1" do
    test "returns a structure from the conn", %{conn: conn} do
      request = Juvet.Router.Request.new(conn)

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

  describe "get_header/2" do
    setup %{conn: conn} do
      [request: Juvet.Router.Request.new(conn)]
    end

    test "returns the header values if found", %{request: request} do
      assert Juvet.Router.Request.get_header(request, "content-type") ==
               ["multipart/mixed; boundary=plug_conn_test"]
    end

    test "returns an empty list of none found", %{request: request} do
      assert Juvet.Router.Request.get_header(request, "blah") == []
    end
  end
end
