defmodule Juvet.TemplateTest do
  use ExUnit.Case, async: false

  alias Juvet.Template

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
    def send_message(_platform, _template, %{pid: pid} = context) do
      send(pid, :called_send_message)

      {:ok, context}
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
               Template.send_message(
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
               Template.send_message(
                 MyTemplateView,
                 :some_template,
                 Map.put(context, :pid, self())
               )

      assert_received :called_template_message
    end

    test "sends a platform message when a default handler", %{context: context} do
      assert {:ok, _context} =
               Template.send_message(
                 MyDefaultView,
                 :some_template,
                 Map.put(context, :pid, self())
               )

      assert_received :called_send_message
    end

    test "raises when there is an unknown request", %{context: context} do
      assert_raise ArgumentError,
                   ~r/^No "unknown" platform with "some_template" template defined/,
                   fn ->
                     Template.send_message(
                       MyTemplateView,
                       :some_template,
                       Map.put(context, :request, nil)
                     )
                   end
    end
  end
end
