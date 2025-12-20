defmodule Juvet.Template.TokenizerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Tokenizer

  describe "tokenize/1" do
    test "empty template returns empty list" do
      assert [] = assert(Tokenizer.tokenize(""))
    end

    test "Slack divider tokenizes correctly" do
      template = """
      :slack.divider
      """

      assert [{:slack, :divider, []}] = Tokenizer.tokenize(template)
    end

    test "Slack header with inline text attribute tokenizes correctly" do
      template = """
      :slack.header{text: "Welcome <%= name %>!"}
      """

      assert [{:slack, :header, [{:text, "\"Welcome <%= name %>!\""}]}] =
               Tokenizer.tokenize(template)
    end

    test "Slack header with inline text tokenizes correctly" do
      template = """
      :slack.header "Welcome <%= name %>! Looking good without the attribute."
      """

      assert [
               {:slack, :header,
                [{:text, "\"Welcome <%= name %>! Looking good without the attribute.\""}]}
             ] = Tokenizer.tokenize(template)
    end

    test "Slack header with empty inline text does not include default attribute" do
      template = """
      :slack.header
      """

      assert [{:slack, :header, []}] = Tokenizer.tokenize(template)
    end
  end
end
