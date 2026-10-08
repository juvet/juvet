defmodule Juvet.HTTPClient.ReqTest do
  use ExUnit.Case, async: true

  alias Juvet.HTTPClient

  test "sends the request and returns status, lowercase headers, and the raw body" do
    Req.Test.stub(Juvet.HTTPClient, fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert conn.method == "POST"
      assert conn.request_path == "/api/team.info"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer TOKEN"]
      assert body == "team=T1"

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, ~s({"ok":true}))
    end)

    assert {:ok, %{status: 200, headers: headers, body: ~s({"ok":true})}} =
             HTTPClient.request(
               :post,
               "https://slack.com/api/team.info",
               [{"authorization", "Bearer TOKEN"}],
               "team=T1"
             )

    assert {"content-type", "application/json; charset=utf-8"} in headers
  end

  test "returns a 429 without retrying" do
    test_pid = self()

    Req.Test.stub(Juvet.HTTPClient, fn conn ->
      send(test_pid, :requested)

      conn
      |> Plug.Conn.put_resp_header("retry-after", "12")
      |> Plug.Conn.send_resp(429, "")
    end)

    assert {:ok, %{status: 429, headers: headers}} =
             HTTPClient.request(:post, "https://slack.com/api/chat.postMessage", [], "")

    assert {"retry-after", "12"} in headers
    assert_received :requested
    refute_received :requested
  end

  test "returns transport errors" do
    Req.Test.stub(Juvet.HTTPClient, &Req.Test.transport_error(&1, :econnrefused))

    assert {:error, %Req.TransportError{reason: :econnrefused}} =
             HTTPClient.request(:get, "https://slack.com/api/api.test", [], "")
  end
end
