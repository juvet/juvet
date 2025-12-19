defmodule Juvet.Template.TokenizerTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.Tokenizer

  describe "tokenize/1" do
    test "empty template returns empty list" do
      assert Tokenizer.tokenize("") == []
    end

    test "Slack divider tokenizes correctly" do
      template = """
      :slack.divider
      """

      assert Tokenizer.tokenize(template) == [{:slack, :divider, []}]
    end

    test "Slack header with inline text attribute tokenizes correctly" do
      # TODO: :slack.header "Welcome <%= name %>!"
      # TODO: :slack.header
      #         text: "Welcome <%= name %>!"
      template = """
      :slack.header{text: "Welcome <%= name %>!"}
      """

      assert [{:slack, :header, [{:text, "Welcome <%= name %>!"}]}], Tokenizer.tokenize(template)
    end
  end
end
