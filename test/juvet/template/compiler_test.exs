defmodule Juvet.Template.CompilerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler

  describe "compile/1" do
    test "empty AST returns empty string" do
      assert Compiler.compile([]) == ""
    end

    test "delegates slack elements to SlackCompiler" do
      ast = [%{platform: :slack, element: :divider, attributes: %{}}]

      assert Compiler.compile(ast) == ~s({"blocks":[{"type":"divider"}]})
    end
  end
end
