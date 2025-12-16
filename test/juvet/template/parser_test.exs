defmodule Juvet.Template.ParserTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Elements.Slack
  alias Juvet.Template.Parser

  describe "parse/1" do
    test "empty tokens returns empty list" do
      assert Parser.parse([]) == []
    end

    test "Slack divider parses correctly" do
      tokens = [{:slack, :divider, []}]

      assert Parser.parse(tokens) == [%Slack.Divider{}]
    end
  end
end
