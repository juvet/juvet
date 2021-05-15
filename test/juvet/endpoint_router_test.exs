defmodule Juvet.EndpointTest do
  use ExUnit.Case, async: true
  use Plug.Test

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

  defp request!(method, path) do
    conn(method, path)
    |> Juvet.EndpointRouter.call(Juvet.EndpointRouter.init([]))
  end
end
