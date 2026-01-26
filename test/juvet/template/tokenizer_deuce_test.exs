defmodule Juvet.Template.TokenizerDeuceTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.TokenizerError
  alias Juvet.Template.TokenizerDeuce, as: Tokenizer

  describe "tokenize/1" do
    test "empty template returns empty list" do
      assert [] = assert(Tokenizer.tokenize(""))
    end

    test "no platform specified raises unknown platform parser error" do
      template = """
      :divider
      """

      assert_raise TokenizerError, "Unknown platform for line 1: :divider", fn ->
        Tokenizer.tokenize(template)
      end
    end
  end
end
