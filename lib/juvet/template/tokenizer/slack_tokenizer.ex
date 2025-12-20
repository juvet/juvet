defmodule Juvet.Template.Tokenizer.SlackTokenizer do
  @moduledoc false

  @attribute_list_separator ~r/,\s*/
  @attribute_separator ~r/:\s*/

  def tokenize_line("divider" <> _rest), do: [:divider, []]

  def tokenize_line("header" <> attributes) do
    [:header, attributes |> tokenize_attributes(default_attribute: :text)]
  end

  # Tokenize attributes

  # Ensures an attribute pair has an atom key.
  defp tokenize_attribute([key, value]) when is_binary(key),
    do: [String.to_atom(key), value] |> tokenize_attribute()

  # This is the base valid format for an attribute pair:
  # {:string_value, "This is the value"}
  # {:boolean_value, false}
  defp tokenize_attribute([key, _value] = valid_attribute_token) when is_atom(key),
    do: valid_attribute_token |> List.to_tuple()

  # The third step in tokenizing attributes is spliting out an individual attribute
  # pair as a string, separated by a comma.
  defp tokenize_attribute(attribute_string) when is_binary(attribute_string),
    do: attribute_string |> String.split(@attribute_separator, trim: true) |> tokenize_attribute()

  # Tokenizing attributes starts here.
  # Attributes start out as strings (obviously) between the separators of { }.
  #
  # This splits out the attribute list that lies between the { } anchors and moves onto
  # splitting an 'attribute list' if the anchors are found.
  defp tokenize_attributes("{" <> attribute_string_with_suffix = attribute_string, _opts)
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
        [attribute_string]
    end
  end

  # Single attribute without a key, so use a default attribute as the key
  defp tokenize_attributes(attribute_string, default_attribute: default_attribute)
       when is_binary(attribute_string),
       do:
         [[default_attribute, attribute_string |> String.trim()]]
         |> Enum.map(&tokenize_attribute/1)

  defp tokenize_attributes(_, _opts), do: []

  # The second step in tokenizing attributes is spliting out the individual attribute pairs
  # as strings separated by commas.
  defp tokenize_attribute_list(attribute_list),
    do:
      attribute_list
      |> String.split(@attribute_list_separator, trim: true)
      |> Enum.map(&tokenize_attribute/1)
end
