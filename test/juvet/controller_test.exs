defmodule Juvet.ControllerTest do
  use ExUnit.Case, async: false
  use Juvet.PlugHelpers

  import Mock

  alias Juvet.Router.Response

  defmodule MyController do
    use Juvet.Controller

    def send_message_test(context, template) do
      context
      |> put_view(MyView)
      |> send_message(template)
    end

    def send_response_test(context, response \\ nil), do: send_response(context, response)

    def update_response_test(context, response), do: update_response(context, response)
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

  describe "view_state/0" do
    test "returns the view state manager" do
      view_state = MyController.view_state()

      assert view_state == Juvet.ViewStateManager
    end
  end

  describe "send_message/2" do
    setup do
      context = %{
        conn: build_conn(:post, "/slack/commands"),
        response: Response.new()
      }

      [context: context]
    end

    test "sends a message via a view and template", %{context: context} do
      with_mock Juvet.Template,
        send_message: fn view, :meeting_reminder, _context ->
          assert view == MyView
          {:ok, Response.new(body: "ok")}
        end do
        MyController.send_message_test(context, :meeting_reminder)
        assert_called(Juvet.Template.send_message(MyView, :meeting_reminder, context))
      end
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
