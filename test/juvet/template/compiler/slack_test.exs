defmodule Juvet.Template.Compiler.SlackTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler.Slack

  describe "compile/1 - Phase 0-1: Basic structure" do
    test "empty AST returns empty blocks" do
      assert Slack.compile([]) == ~s({"blocks":[]})
    end

    test "divider element" do
      ast = [%{platform: :slack, element: :divider, attributes: %{}}]

      assert Slack.compile(ast) == ~s({"blocks":[{"type":"divider"}]})
    end
  end

  describe "compile/1 - Phase 2: Header with plain_text" do
    test "header with text" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello"}}]

      assert Slack.compile(ast) ==
               ~s({"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello"}}]})
    end

    test "header with text and emoji" do
      ast = [%{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}]

      assert Slack.compile(ast) ==
               ~s({"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello","emoji":true}}]})
    end
  end
end
