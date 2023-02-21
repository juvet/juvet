defmodule Juvet.ViewTest do
  use ExUnit.Case, async: false

  import Mock

  alias Juvet.{SlackAPI, View}

  defmodule MyPlatformTemplateView do
    def send_slack_some_template_message(%{pid: pid} = context) do
      send(pid, :called_platform_template_message)

      {:ok, context}
    end
  end

  defmodule MyTemplateView do
    def send_some_template_message(_platform, %{pid: pid} = context) do
      send(pid, :called_template_message)

      {:ok, context}
    end
  end

  defmodule MyDefaultView do
    use View

    def send_message(_platform, _template, %{pid: pid} = context) do
      send(pid, :called_send_message)

      {:ok, context}
    end

    def send_message_to_slack(message, message_id \\ nil),
      do: create_or_update_slack_message(message, message_id)
  end

  describe "create_or_update_slack_message/2" do
    test "sends a new message via Slack API without a message id" do
      message = %{channel: "C1234", blocks: [], text: "Hello World", token: "SLACK_TOKEN"}

      with_mock SlackAPI.Chat, post_message: fn _message -> {:ok, %{}} end do
        MyDefaultView.send_message_to_slack(message)

        assert_called(SlackAPI.Chat.post_message(message))
      end
    end

    test "sends an updated message via Slack API with a message id" do
      message_id = "SLACK.TIMESTAMP"
      message = %{channel: "C1234", blocks: [], text: "Hello World", token: "SLACK_TOKEN"}

      with_mock SlackAPI.Chat,
        update: fn %{ts: timestamp} ->
          assert timestamp == message_id

          {:ok, %{}}
        end do
        MyDefaultView.send_message_to_slack(message, message_id)

        assert_called(SlackAPI.Chat.update(Map.merge(%{ts: :_}, message)))
      end
    end
  end

  describe "send_message/3" do
    setup do
      context = %{request: %{platform: :slack}}

      [context: context]
    end

    test "sends a slack message when there is a Slack request", %{
      context: context
    } do
      assert {:ok, _context} =
               View.send_message(
                 MyPlatformTemplateView,
                 :some_template,
                 Map.put(context, :pid, self())
               )

      assert_received :called_platform_template_message
    end

    test "sends a template message with the platform when there is a Slack request", %{
      context: context
    } do
      assert {:ok, _context} =
               View.send_message(
                 MyTemplateView,
                 :some_template,
                 Map.put(context, :pid, self())
               )

      assert_received :called_template_message
    end

    test "sends a platform message when a default handler", %{context: context} do
      assert {:ok, _context} =
               View.send_message(
                 MyDefaultView,
                 :some_template,
                 Map.put(context, :pid, self())
               )

      assert_received :called_send_message
    end

    test "raises when there is an unknown template", %{context: context} do
      assert_raise ArgumentError,
                   ~r/^No "slack" platform with "some_blah_template" template defined/,
                   fn ->
                     View.send_message(
                       MyTemplateView,
                       :some_blah_template,
                       Map.put(context, :pid, self())
                     )
                   end
    end

    test "raises when there is an unknown request", %{context: context} do
      assert_raise ArgumentError,
                   ~r/^No "unknown" platform with "some_template" template defined/,
                   fn ->
                     View.send_message(
                       MyTemplateView,
                       :some_template,
                       Map.put(context, :request, nil)
                     )
                   end
    end
  end
end
