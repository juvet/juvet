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
end
