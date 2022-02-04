defmodule Juvet.ControllerTest do
  use ExUnit.Case, async: true
  use Juvet.PlugHelpers

  defmodule MyController do
    use Juvet.Controller

    def send_response_test(context) do
      send_response(context)
    end
  end

  describe "send_response/2" do
    setup do
      context = %{
        conn: build_conn(:post, "/slack/commands"),
        response: Juvet.Router.Response.new()
      }

      [context: context]
    end

    test "sends the default response in the context to the requestor", %{context: context} do
      conn = MyController.send_response_test(context)

      assert conn.halted
      assert conn.status == 200
    end
  end
end
