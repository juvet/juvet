defmodule Juvet.Template.ParserTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Elements.Slack
  alias Juvet.Template.Parser

  describe "parse/1" do
    test "empty tokens returns empty list" do
      assert Parser.parse([]) == []
    end

    test "Slack divider parses correctly" do
      tokens = [{:slack, :divider, [blah: "bleh"]}]

      assert Parser.parse(tokens) == [%Slack.DividerElement{}]
    end

    test "Slack header parses correctly" do
      tokens = [{:slack, :header, [text: "Hello there <%= salutation %>"]}]

      assert Parser.parse(tokens) == [
               %Slack.HeaderElement{
                 text: %Slack.TextElement{text: "Hello there <%= salutation %>"}
               }
             ]
    end
  end
end
