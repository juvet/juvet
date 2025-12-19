defmodule Juvet.Template.Tokenizer.SlackTokenizer do
  @moduledoc false

  @attribute_list_separator ~r/,\s*/
  @attribute_separator ~r/:\s*/

  def tokenize_line("divider" <> _rest), do: [:divider, []]

  def tokenize_line("header" <> attributes) do
    [:header, attributes |> tokenize_attributes()]
  end

  # Tokenize attributes

  defp tokenize_attribute([key, value]) when is_binary(key),
    do: [String.to_atom(key), value] |> tokenize_attribute()

  defp tokenize_attribute([key, _value] = valid_attribute_token) when is_atom(key),
    do: valid_attribute_token

  defp tokenize_attribute(attribute_string) when is_binary(attribute_string),
    do: attribute_string |> String.split(@attribute_separator, trim: true) |> tokenize_attribute()

  defp tokenize_attributes("{" <> attribute_string_with_suffix = attribute_string)
       when is_binary(attribute_string) do
    # Attributes are formatted as a list of key-value pairs between anchors { and }
    # e.g. {text: {text: "Welcome <%= name %>!", emoji: false}, id: "view.main-header"}
    case String.ends_with?(attribute_string_with_suffix, "}") do
      true ->
        attribute_string_with_suffix
        |> String.trim_trailing("}")
        |> tokenize_attribute_list()

      false ->
        # Just return the full string as a token since we can't parse it
        attribute_string
    end
  end

  defp tokenize_attributes(_), do: []

  defp tokenize_attribute_list(attribute_list),
    do:
      attribute_list
      |> String.split(@attribute_list_separator, trim: true)
      |> Enum.map(&tokenize_attribute/1)
end
