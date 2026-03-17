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

  defp strip_positions(%{node_type: :for_loop} = node) do
    node
    |> Map.drop([:line, :column])
    |> Map.update!(:body, &strip_positions/1)
  end

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

  describe "parse/1 - Phase 8: Platform inheritance" do
    test "child element inherits platform from parent" do
      template = ":slack.section\n  accessory:\n    .image\n      url: \"http://ex.com\""

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

    test "multiple children inherit platform" do
      template =
        ":slack.actions\n  elements:\n    .button\n      text: \"One\"\n    .button\n      text: \"Two\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :actions,
                 attributes: %{},
                 children: %{
                   elements: [
                     %{platform: :slack, element: :button, attributes: %{text: "One"}},
                     %{platform: :slack, element: :button, attributes: %{text: "Two"}}
                   ]
                 }
               }
             ]
    end

    test "mixed full and shorthand syntax in children" do
      template =
        ":slack.actions\n  elements:\n    :slack.button\n      text: \"Full\"\n    .button\n      text: \"Short\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :actions,
                 attributes: %{},
                 children: %{
                   elements: [
                     %{platform: :slack, element: :button, attributes: %{text: "Full"}},
                     %{platform: :slack, element: :button, attributes: %{text: "Short"}}
                   ]
                 }
               }
             ]
    end

    test "top-level dot element raises error" do
      assert_raise Juvet.Template.Parser.Error,
                   ~r/must be inside a parent/,
                   fn ->
                     parse(".header{text: \"Hello\"}")
                   end
    end

    test "shorthand in view blocks" do
      template =
        ":slack.view\n  type: :modal\n  blocks:\n    .header{text: \"Hello\"}\n    .divider\n    .section \"Welcome\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :view,
                 attributes: %{type: :modal},
                 children: %{
                   blocks: [
                     %{platform: :slack, element: :header, attributes: %{text: "Hello"}},
                     %{platform: :slack, element: :divider, attributes: %{}},
                     %{platform: :slack, element: :section, attributes: %{text: "Welcome"}}
                   ]
                 }
               }
             ]
    end

    test "shorthand with inline attributes" do
      template =
        ":slack.section\n  accessory:\n    .image{url: \"http://ex.com\", alt_text: \"Alt\"}"

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :section,
                 attributes: %{},
                 children: %{
                   accessory: %{
                     platform: :slack,
                     element: :image,
                     attributes: %{url: "http://ex.com", alt_text: "Alt"}
                   }
                 }
               }
             ]
    end
  end

  describe "parse/1 - Phase 9: Nested attributes (deep attributes)" do
    test "basic nested attribute produces a map value" do
      template = ":slack.select\n  placeholder:\n    text: \"Choose a color\""

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :select,
                 attributes: %{placeholder: %{text: "Choose a color"}}
               }
             ]
    end

    test "nested attribute with multiple keys" do
      template = ":slack.select\n  placeholder:\n    text: \"Choose a color\"\n    emoji: true"

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :select,
                 attributes: %{placeholder: %{text: "Choose a color", emoji: true}}
               }
             ]
    end

    test "nested attribute alongside scalar attributes" do
      template =
        ":slack.select\n  source: :static\n  action_id: \"color_sel\"\n  placeholder:\n    text: \"Choose a color\"\n    emoji: true"

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :select,
                 attributes: %{
                   source: :static,
                   action_id: "color_sel",
                   placeholder: %{text: "Choose a color", emoji: true}
                 }
               }
             ]
    end

    test "nested attribute alongside child elements" do
      template =
        ":slack.select\n  source: :static\n  placeholder:\n    text: \"Choose\"\n    emoji: true\n  options:\n    .option{text: \"Red\", value: \"red\"}"

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :select,
                 attributes: %{
                   source: :static,
                   placeholder: %{text: "Choose", emoji: true}
                 },
                 children: %{
                   options: %{
                     platform: :slack,
                     element: :option,
                     attributes: %{text: "Red", value: "red"}
                   }
                 }
               }
             ]
    end

    test "nested attribute with different value types" do
      template =
        ":slack.element\n  config:\n    name: \"test\"\n    enabled: true\n    type: :plain_text\n    count: 42"

      assert parse(template) == [
               %{
                 platform: :slack,
                 element: :element,
                 attributes: %{
                   config: %{name: "test", enabled: true, type: :plain_text, count: 42}
                 }
               }
             ]
    end
  end

  describe "parse/2 - with default platform option" do
    defp parse_with_platform(template, platform) do
      template
      |> Tokenizer.tokenize()
      |> Parser.parse(platform: platform)
      |> strip_positions()
    end

    test "top-level .element allowed when platform is provided" do
      assert parse_with_platform(".header{text: \"Hello\"}", :slack) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}}
             ]
    end

    test "multiple top-level shorthand elements" do
      template = ".header{text: \"Hello\"}\n.divider\n.section \"Welcome\""

      assert parse_with_platform(template, :slack) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}},
               %{platform: :slack, element: :divider, attributes: %{}},
               %{platform: :slack, element: :section, attributes: %{text: "Welcome"}}
             ]
    end

    test "mixed full and shorthand at top level" do
      template = ":slack.header{text: \"Hello\"}\n.divider\n.section \"Welcome\""

      assert parse_with_platform(template, :slack) == [
               %{platform: :slack, element: :header, attributes: %{text: "Hello"}},
               %{platform: :slack, element: :divider, attributes: %{}},
               %{platform: :slack, element: :section, attributes: %{text: "Welcome"}}
             ]
    end

    test "shorthand view with nested children" do
      template = ".view\n  type: :modal\n  blocks:\n    .header{text: \"Hello\"}\n    .divider"

      assert parse_with_platform(template, :slack) == [
               %{
                 platform: :slack,
                 element: :view,
                 attributes: %{type: :modal},
                 children: %{
                   blocks: [
                     %{platform: :slack, element: :header, attributes: %{text: "Hello"}},
                     %{platform: :slack, element: :divider, attributes: %{}}
                   ]
                 }
               }
             ]
    end

    test "top-level .element still errors without platform option" do
      assert_raise Juvet.Template.Parser.Error,
                   ~r/must be inside a parent/,
                   fn ->
                     parse(".header{text: \"Hello\"}")
                   end
    end
  end

  describe "parse/1 - Phase 10: For-loop support" do
    test "simple for-loop produces for_loop AST node" do
      template = "<%= for item <- items do %>\n:slack.section{text: \"<%= item %>\"}\n<% end %>"

      assert parse(template) == [
               %{
                 node_type: :for_loop,
                 variable: "item",
                 collection: "items",
                 body: [
                   %{
                     platform: :slack,
                     element: :section,
                     attributes: %{text: "<%= item %>"}
                   }
                 ]
               }
             ]
    end

    test "for-loop with multiple body elements" do
      template =
        "<%= for item <- items do %>\n:slack.section{text: \"<%= item %>\"}\n:slack.divider\n<% end %>"

      [for_node] = parse(template)

      assert for_node.node_type == :for_loop
      assert length(for_node.body) == 2
      assert Enum.at(for_node.body, 0).element == :section
      assert Enum.at(for_node.body, 1).element == :divider
    end

    test "for-loop inside blocks with platform inheritance" do
      template =
        ":slack.view\n  type: :modal\n  blocks:\n    :slack.header{text: \"Title\"}\n    <%= for item <- items do %>\n    .section{text: \"<%= item %>\"}\n    <% end %>\n    :slack.divider"

      [view] = parse(template)

      assert view.element == :view
      blocks = view.children.blocks
      assert length(blocks) == 3

      [header, for_node, divider] = blocks
      assert header.element == :header
      assert for_node.node_type == :for_loop
      assert for_node.variable == "item"
      assert for_node.collection == "items"
      assert length(for_node.body) == 1
      assert hd(for_node.body).element == :section
      assert hd(for_node.body).platform == :slack
      assert divider.element == :divider
    end

    test "for-loop with EEx expression in value position" do
      template = ":slack.section{text: <%= decision %>, type: :mrkdwn}"

      [section] = parse(template)

      assert section.attributes.text == "<%= decision %>"
      assert section.attributes.type == :mrkdwn
    end

    test "missing end tag raises error" do
      template = "<%= for item <- items do %>\n:slack.section{text: \"Hello\"}"

      assert_raise Juvet.Template.Parser.Error,
                   ~r/expected <% end %> to close for loop/,
                   fn -> parse(template) end
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
