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

    test "element with trailing newline includes newline token" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "divider", {1, 8}},
               {:newline, "\n", {1, 15}},
               {:eof, "", {2, 1}}
             ] = Tokenizer.tokenize(":slack.divider\n")
    end

    test "unexpected character raises error" do
      assert_raise Juvet.Template.TokenizerError,
                   "Unexpected character '@' at line 1, column 1",
                   fn -> Tokenizer.tokenize("@invalid") end
    end
  end
end
