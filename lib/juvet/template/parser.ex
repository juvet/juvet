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

  alias Juvet.Template.ParserError

  def parse(tokens), do: do_parse(tokens, [])

  # Main parsing loop - dispatch based on first token
  defp do_parse([], acc), do: Enum.reverse(acc)
  defp do_parse([{:eof, _, _}], acc), do: Enum.reverse(acc)
  defp do_parse([{:eof, _, _} | rest], acc), do: do_parse(rest, acc)
  defp do_parse([{:dedent, _, _} | rest], acc), do: do_parse(rest, acc)
  defp do_parse([{:newline, _, _} | rest], acc), do: do_parse(rest, acc)

  defp do_parse([{:colon, _, _} | _] = tokens, acc) do
    {el, rest} = element(tokens)
    do_parse(rest, [el | acc])
  end

  # Unexpected token at top level
  defp do_parse([{type, value, {line, col}} | _], _acc) do
    raise ParserError,
      message: "Unexpected #{type} '#{value}' at top level",
      line: line,
      column: col
  end

  # Element parsing - :platform.element_type
  defp element([
         {:colon, _, _},
         {:keyword, platform, _},
         {:dot, _, _},
         {:keyword, el, _}
         | rest
       ]) do
    {attrs_result, rest} = attributes(rest)

    new_element = %{
      platform: String.to_atom(platform),
      element: String.to_atom(el)
    }

    new_element =
      case attrs_result do
        {attrs, children} ->
          new_element
          |> Map.put(:attributes, attrs)
          |> Map.put(:children, children)

        attrs ->
          Map.put(new_element, :attributes, attrs)
      end

    {new_element, rest}
  end

  # Invalid element syntax
  defp element([{:colon, _, {line, col}} | _]) do
    raise ParserError,
      message: "Invalid element syntax, expected :platform.element",
      line: line,
      column: col
  end

  # Attribute dispatching
  defp attributes([{:open_brace, _, _} | rest]), do: inline_attrs(rest, %{})

  # Multi-line block (newline + indent)
  defp attributes([{:newline, _, _}, {:indent, _, _} | rest]) do
    block(rest, %{}, %{})
  end

  # Default value (unquoted text) followed by inline attrs - must come before general text match
  defp attributes([{:whitespace, _, _}, {:text, text, _}, {:open_brace, _, _} | rest]) do
    {more_attrs, rest} = inline_attrs(rest, %{})
    {Map.put(more_attrs, :text, text), rest}
  end

  # Default value (text after whitespace)
  defp attributes([{:whitespace, _, _}, {:text, text, _} | rest]) do
    {maybe_more_attrs, rest} = attributes(rest)
    {Map.put(maybe_more_attrs, :text, unquote_text(text)), rest}
  end

  defp attributes([{:eof, _, _}] = rest), do: {%{}, rest}
  defp attributes(rest), do: {%{}, rest}

  # Block parsing - indented attributes and children until dedent
  defp block([{:dedent, _, _} | rest], attrs, children) do
    if map_size(children) > 0 do
      {{attrs, children}, rest}
    else
      {attrs, rest}
    end
  end

  defp block([{:newline, _, _} | rest], attrs, children), do: block(rest, attrs, children)
  defp block([{:whitespace, _, _} | rest], attrs, children), do: block(rest, attrs, children)

  # Nested element(s) - key followed by newline+indent+colon
  defp block(
         [{:keyword, _, _}, {:colon, _, _}, {:newline, _, _}, {:indent, _, _}, {:colon, _, _} | _] =
           tokens,
         attrs,
         children
       ) do
    [{:keyword, key, _}, {:colon, _, _}, {:newline, _, _}, {:indent, _, _} | rest] = tokens
    {nested_elements, rest} = nested_elements(rest, [])

    # Single element stored as-is, multiple elements stored as list
    child_value =
      case nested_elements do
        [single] -> single
        multiple -> multiple
      end

    block(rest, attrs, Map.put(children, String.to_atom(key), child_value))
  end

  # Regular attribute
  defp block([{:keyword, key, _}, {:colon, _, _} | rest], attrs, children) do
    {val, rest} = value(rest)
    block(rest, Map.put(attrs, String.to_atom(key), val), children)
  end

  # Collect sibling elements until dedent
  defp nested_elements([{:dedent, _, _} | rest], acc), do: {Enum.reverse(acc), rest}
  defp nested_elements([{:newline, _, _} | rest], acc), do: nested_elements(rest, acc)

  defp nested_elements([{:colon, _, _} | _] = tokens, acc) do
    {el, rest} = element(tokens)
    nested_elements(rest, [el | acc])
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
