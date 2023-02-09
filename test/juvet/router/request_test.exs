defmodule Juvet.Router.RequestTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  alias Juvet.Router.Request

  setup_all do
    conn = %Plug.Conn{
      req_headers: [{"content-type", "multipart/mixed"}],
      method: "POST",
      params: %{foo: :bar},
      port: 80,
      request_path: "/slack/commands",
      status: 200
    }

    [conn: conn]
  end

  describe "new/1" do
    test "returns a structure from the conn", %{conn: conn} do
      request = Request.new(conn)

      assert request.headers == [
               {"content-type", "multipart/mixed"}
             ]

      assert request.host == "www.example.com"
      assert request.method == "POST"
      assert request.raw_params == %{foo: :bar}
      assert request.path == "/slack/commands"
      assert request.port == 80
      assert request.private
      assert request.query_string == ""
      assert request.scheme == :http
      assert request.status == 200
      assert request.platform == :unknown
      refute request.verified?
    end
  end

  describe "base_url/1" do
    test "returns a string as the base from the conn", %{conn: conn} do
      request = Request.new(conn)

      assert Request.base_url(request) == "http://www.example.com"
    end
  end

  describe "decode_raw_params/1" do
    test "returns the same params for an unknown platform", %{conn: conn} do
      request = Request.new(conn) |> Request.decode_raw_params()

      assert request.raw_params == conn.params
    end

    test "returns a map of the payload for a Slack platform", %{conn: conn} do
      conn = %{conn | params: %{"payload" => "{\"foo\": \"bar\"}"}}

      request = Request.new(conn)
      request = %{request | platform: :slack}
      request = Request.decode_raw_params(request)

      assert request.raw_params == %{"payload" => %{"foo" => "bar"}}
    end
  end

  describe "get_header/2" do
    setup %{conn: conn} do
      [request: Request.new(conn)]
    end

    test "returns the header values if found", %{request: request} do
      assert Request.get_header(request, "content-type") == [
               "multipart/mixed"
             ]
    end

    test "returns an empty list if there were no headers" do
      request = Request.new(%{})

      assert Request.get_header(request, "blah") == []
    end

    test "returns an empty list of none found", %{request: request} do
      assert Request.get_header(request, "blah") == []
    end
  end
end
