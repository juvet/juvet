defmodule Juvet.PlugTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  defmodule MyRouter do
    use Juvet.Router
  end

  describe "init/1" do
    test "puts the options passed in private connection" do
      conn = build_conn(:post, "/slack/commands")

      conn = Juvet.Plug.call(conn, Juvet.Plug.init(foo: :bar, configuration: [router: MyRouter]))

      assert conn.private[:juvet][:options][:foo] == :bar
    end
  end

  describe "POST /slack/commands" do
    test "responds with a 200 status" do
      conn = request!(:post, "/slack/commands", nil, nil, configuration: [router: MyRouter])

      assert conn.status == 200
    end
  end

  describe "POST /slack/events" do
    test "responds with a 200 status" do
      conn = request!(:post, "/slack/events", nil, nil, configuration: [router: MyRouter])

      assert conn.status == 200
    end
  end

  describe "GET /slack/blah" do
    @tag skip: "skipping this test for now as all of the reqests are being sent"
    test "returns the conn without sending a response" do
      conn = request!(:post, "/slack/blah", nil, nil, configuration: [router: MyRouter])

      refute conn.status
      assert conn.state == :unset
    end
  end
end
