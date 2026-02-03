defmodule Juvet.Template.CompilerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Compiler

  describe "compile/1" do
    test "empty AST returns empty string" do
      assert Compiler.compile([]) == ""
    end

    test "delegates slack elements to Slack compiler" do
      ast = [
        %{
          platform: :slack,
          element: :view,
          attributes: %{type: :modal},
          children: %{
            blocks: [%{platform: :slack, element: :divider, attributes: %{}}]
          }
        }
      ]

      result = Poison.decode!(Compiler.compile(ast))

      assert result["type"] == "modal"
      assert result["blocks"] == [%{"type" => "divider"}]
    end
  end
end
