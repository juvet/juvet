defmodule Juvet.PlugTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  describe "init/1" do
    test "puts the options passed in private connection" do
      conn = build_conn(:post, "/slack/commands")

      conn = Juvet.Plug.call(conn, Juvet.Plug.init(foo: :bar))

      assert conn.private[:juvet][:options][:foo] == :bar
    end
  end

  describe "POST /slack/commands" do
    test "responds with a 200 status" do
      conn = request!(:post, "/slack/commands")

      assert conn.status == 200
    end
  end

  describe "POST /slack/events" do
    test "responds with a 200 status" do
      conn = request!(:post, "/slack/events")

      assert conn.status == 200
    end
  end

  describe "GET /slack/blah" do
    test "responds with a 404 status" do
      conn = request!(:post, "/slack/blah")

      assert conn.status == 404
    end
  end
end
