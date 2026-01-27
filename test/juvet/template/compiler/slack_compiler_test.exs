defmodule Juvet.Template.Compiler.SlackCompilerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler.SlackCompiler

  describe "compile/1 - Phase 0-1: Basic structure" do
    test "empty AST returns empty blocks" do
      assert SlackCompiler.compile([]) == ~s({"blocks":[]})
    end

    test "divider element" do
      ast = [%{platform: :slack, element: :divider, attributes: %{}}]

      assert SlackCompiler.compile(ast) == ~s({"blocks":[{"type":"divider"}]})
    end
  end
end
