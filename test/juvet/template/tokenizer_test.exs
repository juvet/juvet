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
  end
end
