defmodule Juvet.ControllerTest do
  use ExUnit.Case, async: false
  use Juvet.PlugHelpers

  import Mock

  defmodule Controllers.MyController do
    use Juvet.Controller

    def request_format_test(context), do: request_format(context)

    def send_message_test(context, template, assigns \\ []) do
      context
      |> put_view(MyView)
      |> send_message(template, assigns)
    end

    def send_messages_test(context, templates, assigns \\ []) do
      context
      |> put_view(MyView)
      |> send_messages(templates, assigns)
    end

    def send_message_with_default_view_test(context, template, assigns \\ []),
      do: context |> send_message(template, assigns)

    def send_response_test(context, response \\ nil), do: send_response(context, response)

    def update_response_test(context, response), do: update_response(context, response)
  end

  alias Controllers.MyController
  alias Juvet.Router.{Request, Response}

  describe "controller_prefix/1" do
    test "returns the module name without controller suffix" do
      assert Juvet.Controller.controller_prefix(MyController) ==
               "Juvet.ControllerTest.Controllers.My"
    end

    test "returns an empty string if nil is provided" do
      assert Juvet.Controller.controller_prefix(nil) == ""
    end

    test "supports an optional suffix" do
      assert Juvet.Controller.controller_prefix(MyController, suffix: ".") ==
               "Juvet.ControllerTest.Controllers.My."
    end

    test "returns an empty string when nil is provided with a suffix" do
      assert Juvet.Controller.controller_prefix(nil, suffix: ".") == ""
    end
  end

  describe "request_format/1" do
    test "returns :modal if the request is from a Slack message" do
      payload = %{
        "view" => %{"id" => "V12345"},
        "container" => %{"type" => "view"}
      }

      request = %Request{platform: :slack, raw_params: %{"payload" => payload}}
      context = %{request: request}

      assert MyController.request_format_test(context) == :modal
    end
  end

  describe "request_format_from/1" do
    test "returns :message if the request is from a Slack message" do
      payload = %{
        "message" => %{
          "ts" => "1234567890.123456"
        },
        "response_url" => "https://hooks.slack.com/commands/1234/5678"
      }

      request = %Request{platform: :slack, raw_params: %{"payload" => payload}}

      assert Juvet.Controller.request_format_from(request) == :message
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
      with_mock Juvet.View,
        send_message: fn view, :meeting_reminder, _context ->
          assert view == MyView
          {:ok, Response.new(body: "ok")}
        end do
        MyController.send_message_test(context, :meeting_reminder)
        assert_called(Juvet.View.send_message(MyView, :meeting_reminder, context))
      end
    end

    test "clears the view from the context after sending the message", %{context: context} do
      with_mock Juvet.View,
        send_message: fn _view, :meeting_reminder, context -> {:ok, context} end do
        assert {:ok, context} = MyController.send_message_test(context, :meeting_reminder)

        refute Map.has_key?(context, :juvet_view)
      end
    end

    test "sends a message via a default view based on the template and controller", %{
      context: context
    } do
      expected_view = "Juvet.ControllerTest.Views.My.MeetingReminderView"

      with_mock Juvet.View,
                [:passthrough],
                send_message: fn view, :meeting_reminder, _context ->
                  assert view == expected_view
                  {:ok, Response.new(body: "ok")}
                end do
        MyController.send_message_with_default_view_test(context, :meeting_reminder)

        assert_called(Juvet.View.send_message(expected_view, :meeting_reminder, context))
      end
    end

    test "merges any additional assigns in the context", %{context: context} do
      with_mock Juvet.View,
        send_message: fn _view, :meeting_reminder, new_context ->
          assert new_context[:newkey] == :newvalue
          {:ok, new_context}
        end do
        MyController.send_message_test(context, :meeting_reminder, newkey: :newvalue)
      end
    end
  end

  describe "send_messages/2" do
    test "sends one or more messages within the same context" do
      with_mocks [
        {Juvet.View, [],
         [send_message: fn _view, template, _context -> {:ok, %{template: template}} end]}
      ] do
        MyController.send_messages_test(%{}, [:meeting_reminder, :another_reminder])

        assert_called(Juvet.View.send_message(MyView, :meeting_reminder, %{}))
        assert_called(Juvet.View.send_message(MyView, :another_reminder, %{}))
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
