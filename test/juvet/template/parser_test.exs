defmodule Juvet.Template.ParserTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.{Parser, Tokenizer}

  defp parse(template) do
    template
    |> Tokenizer.tokenize()
    |> Parser.parse()
  end

  describe "parse/1 - Phase 1: Basic elements" do
    test "empty template returns empty list" do
      assert parse("") == []
    end

    test "simple element with no attributes" do
      assert parse(":slack.divider") == [
               %{platform: :slack, element: :divider, attributes: %{}}
             ]
    end

    test "element with different platform and type" do
      assert parse(":slack.header") == [
               %{platform: :slack, element: :header, attributes: %{}}
             ]
    end
  end

  describe "parse/1 - Phase 2: Inline attributes" do
    test "element with single text attribute" do
      assert parse(~s(:slack.header{text: "Hello"})) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}}
             ]
    end

    test "element with multiple attributes" do
      assert parse(~s(:slack.header{text: "Hello", emoji: true})) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}
             ]
    end

    test "element with boolean false" do
      assert parse(~s(:slack.header{emoji: false})) == [
               %{platform: :slack, element: :header, attributes: %{emoji: false}}
             ]
    end

    test "element with atom value" do
      assert parse(~s(:slack.text{type: :plain_text})) == [
               %{platform: :slack, element: :text, attributes: %{type: :plain_text}}
             ]
    end

    test "element with number value" do
      assert parse(~s(:slack.image{width: 100})) == [
               %{platform: :slack, element: :image, attributes: %{width: 100}}
             ]
    end

    test "element with float value" do
      assert parse(~s(:slack.element{rate: 3.14})) == [
               %{platform: :slack, element: :element, attributes: %{rate: 3.14}}
             ]
    end

    test "element with empty braces" do
      assert parse(":slack.divider{}") == [
               %{platform: :slack, element: :divider, attributes: %{}}
             ]
    end
  end
end
