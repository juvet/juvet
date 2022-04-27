defmodule Juvet.ControllerTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  alias Juvet.Router.Response

  defmodule MyController do
    use Juvet.Controller

    def send_response_test(context, response \\ nil) do
      send_response(context, response)
    end

    def update_response_test(context, response) do
      update_response(context, response)
    end
  end

  describe "update_response/2" do
    setup do
      context = %{
        conn: build_conn(:post, "/slack/commands"),
        response: Response.new(body: "old")
      }

      [context: context]
    end

    test "updates the response in the context", %{context: context} do
      %{response: response} =
        MyController.update_response_test(context, Response.new(body: "new"))

      assert response.body == "new"
    end
  end

  describe "send_response/2" do
    setup do
      context = %{
        conn: build_conn(:post, "/slack/commands"),
        response: Response.new()
      }

      [context: context]
    end

    test "sends the default response in the context to the requestor", %{context: context} do
      %{conn: conn} = MyController.send_response_test(context)

      assert conn.halted
      assert conn.status == 200
    end

    test "can send an optional different request", %{context: context} do
      %{conn: conn, response: response} =
        MyController.send_response_test(context, Response.new(status: 404))

      assert conn.status == 404
      assert response.status == 404
    end
  end
end
