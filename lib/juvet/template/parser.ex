defmodule Juvet.Template.Parser do
  @moduledoc """
  Parses a list of tokens into an AST (Abstract Syntax Tree).

  ## Input

  A list of tokens from `Juvet.Template.Tokenizer.tokenize/1`.
  Each token is a tuple: `{type, value, {line, col}}`

  ## Output

  A list of element maps, where each element has:

      %{
        platform: :slack,
        element: :header,
        attributes: %{text: "Hello", emoji: true},
        children: %{...}   # optional, for nested elements
      }

  ## Example

      iex> tokens = Juvet.Template.Tokenizer.tokenize(":slack.header{text: \\"Hello\\"}")
      iex> Juvet.Template.Parser.parse(tokens)
      [%{platform: :slack, element: :header, attributes: %{text: "Hello"}}]

  See `docs/templates.md` for the full pipeline documentation.
  """

  alias Juvet.Template.Parser.Error, as: ParserError

  def parse(tokens), do: do_parse(tokens, [], nil)

  def parse(tokens, opts) when is_list(opts) do
    platform = Keyword.get(opts, :platform)
    do_parse(tokens, [], platform)
  end

  # Main parsing loop - dispatch based on first token
  defp do_parse([], acc, _platform), do: Enum.reverse(acc)
  defp do_parse([{:eof, _, _}], acc, _platform), do: Enum.reverse(acc)
  defp do_parse([{:eof, _, _} | rest], acc, platform), do: do_parse(rest, acc, platform)
  defp do_parse([{:dedent, _, _} | rest], acc, platform), do: do_parse(rest, acc, platform)
  defp do_parse([{:newline, _, _} | rest], acc, platform), do: do_parse(rest, acc, platform)

  defp do_parse([{:colon, _, _} | _] = tokens, acc, platform) do
    {el, rest} = element(tokens)
    do_parse(rest, [el | acc], platform)
  end

  # Dot shorthand at top level with a default platform - allowed
  defp do_parse([{:dot, _, _} | _] = tokens, acc, platform) when platform != nil do
    {el, rest} = element(tokens, platform)
    do_parse(rest, [el | acc], platform)
  end

  # Dot shorthand at top level is an error - no parent platform to inherit from
  defp do_parse([{:dot, _, {line, col}} | _], _acc, _platform) do
    raise ParserError,
      message:
        "Element with '.' shorthand must be inside a parent element that specifies a platform",
      line: line,
      column: col
  end

  # Unexpected token at top level
  defp do_parse([{type, value, {line, col}} | _], _acc, _platform) do
    raise ParserError,
      message: "Unexpected #{type} '#{value}' at top level",
      line: line,
      column: col
  end

  # Element parsing - :platform.element_type (full syntax)
  defp element([
         {:colon, _, {line, col}},
         {:keyword, platform, _},
         {:dot, _, _},
         {:keyword, el, _}
         | rest
       ]) do
    platform_atom = String.to_atom(platform)
    {attrs_result, rest} = attributes(rest, platform_atom)

    new_element = %{
      platform: platform_atom,
      element: String.to_atom(el),
      line: line,
      column: col
    }

    new_element = apply_attrs_result(new_element, attrs_result)

    {new_element, rest}
  end

  # Invalid element syntax
  defp element([{:colon, _, {line, col}} | _]) do
    raise ParserError,
      message: "Invalid element syntax, expected :platform.element",
      line: line,
      column: col
  end

  # Element parsing - .element_type (inherited platform shorthand)
  defp element([{:dot, _, {line, col}}, {:keyword, el, _} | rest], platform) do
    {attrs_result, rest} = attributes(rest, platform)

    new_element = %{
      platform: platform,
      element: String.to_atom(el),
      line: line,
      column: col
    }

    new_element = apply_attrs_result(new_element, attrs_result)

    {new_element, rest}
  end

  defp apply_attrs_result(element, {attrs, children}) do
    element
    |> Map.put(:attributes, attrs)
    |> Map.put(:children, children)
  end

  defp apply_attrs_result(element, attrs) do
    Map.put(element, :attributes, attrs)
  end

  # Attribute dispatching
  defp attributes([{:open_brace, _, _} | rest], _platform), do: inline_attrs(rest, %{})

  # Multi-line block (newline + indent)
  defp attributes([{:newline, _, _}, {:indent, _, _} | rest], platform) do
    block(rest, %{}, %{}, platform)
  end

  # Default value (unquoted text) followed by inline attrs - must come before general text match
  defp attributes([{:whitespace, _, _}, {:text, text, _}, {:open_brace, _, _} | rest], _platform) do
    {more_attrs, rest} = inline_attrs(rest, %{})
    {Map.put(more_attrs, :text, text), rest}
  end

  # Default value (text after whitespace)
  defp attributes([{:whitespace, _, _}, {:text, text, _} | rest], platform) do
    {maybe_more_attrs, rest} = attributes(rest, platform)
    {Map.put(maybe_more_attrs, :text, unquote_text(text)), rest}
  end

  defp attributes([{:eof, _, _}] = rest, _platform), do: {%{}, rest}
  defp attributes(rest, _platform), do: {%{}, rest}

  # Block parsing - indented attributes and children until dedent
  defp block([{:dedent, _, _} | rest], attrs, children, _platform) do
    if map_size(children) > 0 do
      {{attrs, children}, rest}
    else
      {attrs, rest}
    end
  end

  defp block([{:newline, _, _} | rest], attrs, children, platform),
    do: block(rest, attrs, children, platform)

  defp block([{:whitespace, _, _} | rest], attrs, children, platform),
    do: block(rest, attrs, children, platform)

  # Nested element(s) - key followed by newline+indent+element start (:colon or .dot)
  defp block(
         [{:keyword, _, _}, {:colon, _, _}, {:newline, _, _}, {:indent, _, _}, {start, _, _} | _] =
           tokens,
         attrs,
         children,
         platform
       )
       when start in [:colon, :dot] do
    [{:keyword, key, _}, {:colon, _, _}, {:newline, _, _}, {:indent, _, _} | rest] = tokens
    {nested, rest} = nested_elements(rest, [], platform)

    block(rest, attrs, Map.put(children, String.to_atom(key), child_value(nested)), platform)
  end

  # Nested attributes - key followed by newline+indent+keyword (not element start)
  #
  # Example cheex:
  #   placeholder:
  #     text: "Choose a color"
  #     emoji: true
  #
  # Produces: %{placeholder: %{text: "Choose a color", emoji: true}}
  defp block(
         [
           {:keyword, _, _},
           {:colon, _, _},
           {:newline, _, _},
           {:indent, _, _},
           {:keyword, _, _} | _
         ] = tokens,
         attrs,
         children,
         platform
       ) do
    [{:keyword, key, _}, {:colon, _, _}, {:newline, _, _}, {:indent, _, _} | rest] = tokens
    {nested_map, rest} = nested_attrs(rest, %{})
    block(rest, Map.put(attrs, String.to_atom(key), nested_map), children, platform)
  end

  # Regular attribute
  defp block([{:keyword, key, _}, {:colon, _, _} | rest], attrs, children, platform) do
    {val, rest} = value(rest)
    block(rest, Map.put(attrs, String.to_atom(key), val), children, platform)
  end

  # Single element stored as-is, multiple elements stored as list
  defp child_value([single]), do: single
  defp child_value(multiple), do: multiple

  # Collect sibling elements until dedent
  defp nested_elements([{:dedent, _, _} | rest], acc, _platform), do: {Enum.reverse(acc), rest}

  defp nested_elements([{:newline, _, _} | rest], acc, platform),
    do: nested_elements(rest, acc, platform)

  # Full syntax: :platform.element
  defp nested_elements([{:colon, _, _} | _] = tokens, acc, platform) do
    {el, rest} = element(tokens)
    nested_elements(rest, [el | acc], platform)
  end

  # Inherited syntax: .element
  defp nested_elements([{:dot, _, _} | _] = tokens, acc, platform) do
    {el, rest} = element(tokens, platform)
    nested_elements(rest, [el | acc], platform)
  end

  # Collect nested key-value pairs into a map until dedent.
  #
  # Example token stream for:
  #   text: "Choose"
  #   emoji: true
  #
  # Returns: {%{text: "Choose", emoji: true}, remaining_tokens}
  defp nested_attrs([{:dedent, _, _} | rest], acc), do: {acc, rest}
  defp nested_attrs([{:newline, _, _} | rest], acc), do: nested_attrs(rest, acc)
  defp nested_attrs([{:whitespace, _, _} | rest], acc), do: nested_attrs(rest, acc)

  defp nested_attrs([{:keyword, key, _}, {:colon, _, _} | rest], acc) do
    {val, rest} = value(rest)
    nested_attrs(rest, Map.put(acc, String.to_atom(key), val))
  end

  # Inline attributes - parse {key: value, ...}
  defp inline_attrs([{:close_brace, _, _} | rest], acc), do: {acc, rest}
  defp inline_attrs([{:comma, _, _} | rest], acc), do: inline_attrs(rest, acc)
  defp inline_attrs([{:whitespace, _, _} | rest], acc), do: inline_attrs(rest, acc)

  defp inline_attrs([{:keyword, key, _}, {:colon, _, _} | rest], acc) do
    {val, rest} = value(rest)
    inline_attrs(rest, Map.put(acc, String.to_atom(key), val))
  end

  # Unexpected token in inline attributes
  defp inline_attrs([{type, value, {line, col}} | _], _acc) do
    raise ParserError,
      message: "Unexpected #{type} '#{value}' in attributes, expected key: value",
      line: line,
      column: col
  end

  # Value parsing
  defp value([{:whitespace, _, _} | rest]), do: value(rest)
  defp value([{:text, text, _} | rest]), do: {unquote_text(text), rest}
  defp value([{:boolean, "true", _} | rest]), do: {true, rest}
  defp value([{:boolean, "false", _} | rest]), do: {false, rest}
  defp value([{:atom, atom_str, _} | rest]), do: {parse_atom(atom_str), rest}
  defp value([{:number, num_str, _} | rest]), do: {parse_number(num_str), rest}

  # Unexpected value type
  defp value([{type, val, {line, col}} | _]) do
    raise ParserError,
      message: "Unexpected #{type} '#{val}', expected a value",
      line: line,
      column: col
  end

  defp value([]) do
    raise ParserError,
      message: "Unexpected end of input, expected a value",
      line: nil,
      column: nil
  end

  # Helper functions
  defp unquote_text(text) do
    text
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
  end

  defp parse_atom(":" <> name), do: String.to_atom(name)
  defp parse_atom(name), do: String.to_atom(name)

  defp parse_number(str) do
    if String.contains?(str, ".") do
      String.to_float(str)
    else
      String.to_integer(str)
    end
  end
end
