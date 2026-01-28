defmodule Juvet.Template.ParserTest do
  use ExUnit.Case, async: true

  alias Juvet.Template.{Parser, Tokenizer}

  # Parse template and strip line/column info for cleaner test assertions
  defp parse(template) do
    template
    |> Tokenizer.tokenize()
    |> Parser.parse()
    |> strip_positions()
  end

  # Parse template and keep line/column info for position tests
  defp parse_with_positions(template) do
    template
    |> Tokenizer.tokenize()
    |> Parser.parse()
  end

  defp strip_positions(ast) when is_list(ast), do: Enum.map(ast, &strip_positions/1)

  defp strip_positions(%{} = element) do
    element
    |> Map.drop([:line, :column])
    |> Map.new(fn
      {:children, children} -> {:children, strip_positions_from_children(children)}
      other -> other
    end)
  end

  defp strip_positions_from_children(%{} = children) do
    Map.new(children, fn
      {key, value} when is_list(value) -> {key, strip_positions(value)}
      {key, value} when is_map(value) -> {key, strip_positions(value)}
      other -> other
    end)
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

  describe "parse/1 - Phase 3: Default values" do
    test "element with quoted default value" do
      assert parse(~s(:slack.header "Hello")) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}}
             ]
    end

    test "element with unquoted default value" do
      assert parse(":slack.section Hello world") == [
               %{platform: :slack, element: :section, attributes: %{text: "Hello world"}}
             ]
    end

    test "element with default value and inline attributes" do
      assert parse(~s(:slack.section Hello{emoji: true})) == [
               %{platform: :slack, element: :section, attributes: %{text: "Hello", emoji: true}}
             ]
    end
  end

  describe "parse/1 - Phase 4: Multi-line with indent/dedent" do
    test "element with indented attributes" do
      template = ":slack.header\n  text: \"Hello\""

      assert parse(template) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}}
             ]
    end

    test "element with multiple indented attributes" do
      template = ":slack.header\n  text: \"Hello\"\n  emoji: true"

      assert parse(template) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}
             ]
    end
  end

  describe "parse/1 - Phase 5: Nested elements" do
    test "element with nested child" do
      template = ":slack.section\n  accessory:\n    :slack.image\n      url: \"http://ex.com\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :section,
                 attributes: %{},
                 children: %{
                   accessory: %{
                     platform: :slack,
                     element: :image,
                     attributes: %{url: "http://ex.com"}
                   }
                 }
               }
             ]
    end
  end

  describe "parse/1 - Phase 6: Multiple top-level elements" do
    test "two simple elements" do
      template = ":slack.header\n:slack.divider"

      assert parse(template) == [
               %{platform: :slack, element: :header, attributes: %{}},
               %{platform: :slack, element: :divider, attributes: %{}}
             ]
    end

    test "multiple elements with different attribute styles" do
      template = ~s(:slack.header{text: "Welcome"}\n:slack.divider\n:slack.section "Main content")

      assert parse(template) == [
               %{platform: :slack, element: :header, attributes: %{text: "Welcome"}},
               %{platform: :slack, element: :divider, attributes: %{}},
               %{platform: :slack, element: :section, attributes: %{text: "Main content"}}
             ]
    end

    test "elements with blank lines between" do
      template = ":slack.header\n\n\n:slack.divider"

      assert parse(template) == [
               %{platform: :slack, element: :header, attributes: %{}},
               %{platform: :slack, element: :divider, attributes: %{}}
             ]
    end

    test "multi-line element followed by simple element" do
      template = ":slack.header\n  text: \"Hello\"\n:slack.divider"

      assert parse(template) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}},
               %{platform: :slack, element: :divider, attributes: %{}}
             ]
    end
  end

  describe "parse/1 - Phase 7: List children" do
    test "element with multiple children under same key" do
      template =
        ":slack.actions\n  elements:\n    :slack.button\n      text: \"Button 1\"\n    :slack.button\n      text: \"Button 2\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :actions,
                 attributes: %{},
                 children: %{
                   elements: [
                     %{platform: :slack, element: :button, attributes: %{text: "Button 1"}},
                     %{platform: :slack, element: :button, attributes: %{text: "Button 2"}}
                   ]
                 }
               }
             ]
    end

    test "single child still works (not wrapped in list)" do
      template = ":slack.section\n  accessory:\n    :slack.image\n      url: \"http://ex.com\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :section,
                 attributes: %{},
                 children: %{
                   accessory: %{
                     platform: :slack,
                     element: :image,
                     attributes: %{url: "http://ex.com"}
                   }
                 }
               }
             ]
    end

    test "three children in a list" do
      template =
        ":slack.actions\n  elements:\n    :slack.button\n      text: \"One\"\n    :slack.button\n      text: \"Two\"\n    :slack.button\n      text: \"Three\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :actions,
                 attributes: %{},
                 children: %{
                   elements: [
                     %{platform: :slack, element: :button, attributes: %{text: "One"}},
                     %{platform: :slack, element: :button, attributes: %{text: "Two"}},
                     %{platform: :slack, element: :button, attributes: %{text: "Three"}}
                   ]
                 }
               }
             ]
    end
  end

  describe "parse/1 - line/column tracking" do
    test "includes line and column in AST elements" do
      [element] = parse_with_positions(":slack.header{text: \"Hello\"}")

      assert element.line == 1
      assert element.column == 1
    end

    test "tracks positions across multiple lines" do
      template = """
      :slack.header{text: "Title"}
      :slack.divider
      """

      [first, second] = parse_with_positions(template)

      assert first.line == 1
      assert first.column == 1
      assert second.line == 2
      assert second.column == 1
    end

    test "tracks positions in nested elements" do
      template = ":slack.section\n  accessory:\n    :slack.image\n      url: \"http://ex.com\""

      [section] = parse_with_positions(template)
      image = section.children.accessory

      assert section.line == 1
      assert section.column == 1
      assert image.line == 3
      assert image.column == 5
    end
  end
end
