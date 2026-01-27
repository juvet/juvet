defmodule Juvet.Template.Compiler.SlackTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler.Slack

  # Helper to compare JSON by decoding to maps (avoids key ordering issues)
  defp json_equal?(json_string, expected_map) do
    Jason.decode!(json_string) == expected_map
  end

  describe "compile/1 - Phase 0-1: Basic structure" do
    test "empty AST returns empty blocks" do
      assert json_equal?(Slack.compile([]), %{"blocks" => []})
    end

    test "divider element" do
      ast = [%{platform: :slack, element: :divider, attributes: %{}}]

      assert json_equal?(Slack.compile(ast), %{"blocks" => [%{"type" => "divider"}]})
    end
  end

  describe "compile/1 - Phase 2: Header with plain_text" do
    test "header with text" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{"type" => "header", "text" => %{"type" => "plain_text", "text" => "Hello"}}
               ]
             })
    end

    test "header with text and emoji" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "header",
                   "text" => %{"type" => "plain_text", "text" => "Hello", "emoji" => true}
                 }
               ]
             })
    end
  end

  describe "compile/1 - Phase 3: Section with mrkdwn" do
    test "section with text" do
      ast = [%{platform: :slack, element: :section, attributes: %{text: "Hello *world*"}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Hello *world*"}
                 }
               ]
             })
    end

    test "section with text and verbatim" do
      ast = [%{platform: :slack, element: :section, attributes: %{text: "Hello", verbatim: true}}]

      assert json_equal?(Slack.compile(ast), %{
               "blocks" => [
                 %{
                   "type" => "section",
                   "text" => %{"type" => "mrkdwn", "text" => "Hello", "verbatim" => true}
                 }
               ]
             })
    end
  end
end
