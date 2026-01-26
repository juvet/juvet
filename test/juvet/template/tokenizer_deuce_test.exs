defmodule Juvet.Template.TokenizerDeuceTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.TokenizerDeuce, as: Tokenizer

  describe "tokenize/1" do
    test "empty template returns eof token" do
      assert [{:eof, "", {1, 1}}] = Tokenizer.tokenize("")
    end

    test "simple element returns expected tokens" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "divider", {1, 8}},
               {:eof, "", {1, 15}}
             ] = Tokenizer.tokenize(":slack.divider")
    end
  end
end
