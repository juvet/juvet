defmodule Juvet.Template.TokenizerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Tokenizer

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
                   "Unexpected character '@' (line 1, column 1)",
                   fn -> Tokenizer.tokenize("@invalid") end
    end

    test "element with empty braces" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:open_brace, "{", {1, 14}},
               {:close_brace, "}", {1, 15}},
               {:eof, "", {1, 16}}
             ] = Tokenizer.tokenize(":slack.header{}")
    end

    test "element with whitespace before braces" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:whitespace, " ", {1, 14}},
               {:open_brace, "{", {1, 15}},
               {:close_brace, "}", {1, 16}},
               {:eof, "", {1, 17}}
             ] = Tokenizer.tokenize(":slack.header {}")
    end

    test "whitespace includes tabs" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:whitespace, "\t ", {1, 14}},
               {:open_brace, "{", {1, 16}},
               {:close_brace, "}", {1, 17}},
               {:eof, "", {1, 18}}
             ] = Tokenizer.tokenize(":slack.header\t {}")
    end

    test "quoted text in attributes" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:open_brace, "{", {1, 14}},
               {:keyword, "text", {1, 15}},
               {:colon, ":", {1, 19}},
               {:whitespace, " ", {1, 20}},
               {:text, "\"Hello\"", {1, 21}},
               {:close_brace, "}", {1, 28}},
               {:eof, "", {1, 29}}
             ] = Tokenizer.tokenize(":slack.header{text: \"Hello\"}")
    end

    test "boolean values" do
      assert [
               {:open_brace, "{", {1, 1}},
               {:keyword, "emoji", {1, 2}},
               {:colon, ":", {1, 7}},
               {:whitespace, " ", {1, 8}},
               {:boolean, "true", {1, 9}},
               {:close_brace, "}", {1, 13}},
               {:eof, "", {1, 14}}
             ] = Tokenizer.tokenize("{emoji: true}")
    end

    test "comma separates attributes" do
      assert [
               {:open_brace, "{", {1, 1}},
               {:keyword, "a", {1, 2}},
               {:colon, ":", {1, 3}},
               {:whitespace, " ", {1, 4}},
               {:boolean, "true", {1, 5}},
               {:comma, ",", {1, 9}},
               {:whitespace, " ", {1, 10}},
               {:keyword, "b", {1, 11}},
               {:colon, ":", {1, 12}},
               {:whitespace, " ", {1, 13}},
               {:boolean, "false", {1, 14}},
               {:close_brace, "}", {1, 19}},
               {:eof, "", {1, 20}}
             ] = Tokenizer.tokenize("{a: true, b: false}")
    end

    test "atom value after whitespace" do
      assert [
               {:open_brace, "{", {1, 1}},
               {:keyword, "type", {1, 2}},
               {:colon, ":", {1, 6}},
               {:whitespace, " ", {1, 7}},
               {:atom, ":plain_text", {1, 8}},
               {:close_brace, "}", {1, 19}},
               {:eof, "", {1, 20}}
             ] = Tokenizer.tokenize("{type: :plain_text}")
    end

    test "integer number" do
      assert [
               {:open_brace, "{", {1, 1}},
               {:keyword, "count", {1, 2}},
               {:colon, ":", {1, 7}},
               {:whitespace, " ", {1, 8}},
               {:number, "42", {1, 9}},
               {:close_brace, "}", {1, 11}},
               {:eof, "", {1, 12}}
             ] = Tokenizer.tokenize("{count: 42}")
    end

    test "float number" do
      assert [
               {:open_brace, "{", {1, 1}},
               {:keyword, "rate", {1, 2}},
               {:colon, ":", {1, 6}},
               {:whitespace, " ", {1, 7}},
               {:number, "3.14", {1, 8}},
               {:close_brace, "}", {1, 12}},
               {:eof, "", {1, 13}}
             ] = Tokenizer.tokenize("{rate: 3.14}")
    end

    test "unquoted text as default value" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "section", {1, 8}},
               {:whitespace, " ", {1, 15}},
               {:text, "Hello world", {1, 16}},
               {:eof, "", {1, 27}}
             ] = Tokenizer.tokenize(":slack.section Hello world")
    end

    test "unquoted text stops at open brace" do
      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "section", {1, 8}},
               {:whitespace, " ", {1, 15}},
               {:text, "Hello", {1, 16}},
               {:open_brace, "{", {1, 21}},
               {:close_brace, "}", {1, 22}},
               {:eof, "", {1, 23}}
             ] = Tokenizer.tokenize(":slack.section Hello{}")
    end

    test "simple indent" do
      template = ":slack.header\n  text: \"Hello\""

      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:newline, "\n", {1, 14}},
               {:indent, "  ", {2, 1}},
               {:keyword, "text", {2, 3}},
               {:colon, ":", {2, 7}},
               {:whitespace, " ", {2, 8}},
               {:text, "\"Hello\"", {2, 9}},
               {:dedent, "", {2, 16}},
               {:eof, "", {2, 16}}
             ] = Tokenizer.tokenize(template)
    end

    test "multiple attributes at same indent level" do
      template = ":slack.header\n  text: \"Hello\"\n  emoji: true"

      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:newline, "\n", {1, 14}},
               {:indent, "  ", {2, 1}},
               {:keyword, "text", {2, 3}},
               {:colon, ":", {2, 7}},
               {:whitespace, " ", {2, 8}},
               {:text, "\"Hello\"", {2, 9}},
               {:newline, "\n", {2, 16}},
               {:keyword, "emoji", {3, 3}},
               {:colon, ":", {3, 8}},
               {:whitespace, " ", {3, 9}},
               {:boolean, "true", {3, 10}},
               {:dedent, "", {3, 14}},
               {:eof, "", {3, 14}}
             ] = Tokenizer.tokenize(template)
    end

    test "nested indent with multi-level dedent" do
      template = ":slack.section\n  accessory:\n    :image\n:slack.divider"

      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "section", {1, 8}},
               {:newline, "\n", {1, 15}},
               {:indent, "  ", {2, 1}},
               {:keyword, "accessory", {2, 3}},
               {:colon, ":", {2, 12}},
               {:newline, "\n", {2, 13}},
               {:indent, "    ", {3, 1}},
               {:colon, ":", {3, 5}},
               {:keyword, "image", {3, 6}},
               {:newline, "\n", {3, 11}},
               {:dedent, "", {4, 1}},
               {:dedent, "", {4, 1}},
               {:colon, ":", {4, 1}},
               {:keyword, "slack", {4, 2}},
               {:dot, ".", {4, 7}},
               {:keyword, "divider", {4, 8}},
               {:eof, "", {4, 15}}
             ] = Tokenizer.tokenize(template)
    end

    # Edge cases

    test "unclosed quote raises error" do
      assert_raise Juvet.Template.TokenizerError,
                   "Unclosed string (line 1, column 1)",
                   fn -> Tokenizer.tokenize("\"Hello") end
    end

    test "empty string" do
      assert [
               {:text, "\"\"", {1, 1}},
               {:eof, "", {1, 3}}
             ] = Tokenizer.tokenize("\"\"")
    end

    test "escaped quotes in string" do
      assert [
               {:text, ~s("Hello \\"world\\""), {1, 1}},
               {:eof, "", {1, 18}}
             ] = Tokenizer.tokenize(~s("Hello \\"world\\""))
    end

    test "negative number" do
      assert [
               {:open_brace, "{", {1, 1}},
               {:keyword, "count", {1, 2}},
               {:colon, ":", {1, 7}},
               {:whitespace, " ", {1, 8}},
               {:number, "-42", {1, 9}},
               {:close_brace, "}", {1, 12}},
               {:eof, "", {1, 13}}
             ] = Tokenizer.tokenize("{count: -42}")
    end

    test "multiple consecutive newlines" do
      template = ":slack.header\n\n\n:slack.divider"

      assert [
               {:colon, ":", {1, 1}},
               {:keyword, "slack", {1, 2}},
               {:dot, ".", {1, 7}},
               {:keyword, "header", {1, 8}},
               {:newline, "\n", {1, 14}},
               {:newline, "\n", {2, 1}},
               {:newline, "\n", {3, 1}},
               {:colon, ":", {4, 1}},
               {:keyword, "slack", {4, 2}},
               {:dot, ".", {4, 7}},
               {:keyword, "divider", {4, 8}},
               {:eof, "", {4, 15}}
             ] = Tokenizer.tokenize(template)
    end
  end
end
