defmodule Juvet.Template.TokenizerDeuce do
  @moduledoc """
  Reads the content of a template and tokenizes the content into a list of tokens that can be processed by the Parser.

  The Tokenizer handles various template structures, including single-line elements, multi-line elements with attributes,
  default attributes, and nested elements.

  The Tokenizer ensures that the template structure is correct but does not infer meaning about the tokens.
  That is the job of the Parser.

  ## Token Structure

  Every token is a tuple in the form of:

      {token_type, value, {line, column}}

  Where:
  - `token_type` - an atom identifying the kind of token
  - `value` - the string value captured from the template
  - `{line, column}` - position in the source for error reporting (1-indexed)

  ## Token Types (Level 1)

  These tokens handle the simplest template case (e.g., `:slack.divider`):

  | Token      | Description                                              | Example |
  |------------|----------------------------------------------------------|---------|
  | `:colon`   | The `:` character that begins a platform or element      | `:`     |
  | `:keyword` | A sequence of alphanumeric characters and underscores    | `slack` |
  | `:dot`     | The `.` separator between platform and element           | `.`     |
  | `:newline` | Line break character                                     | `\n`    |
  | `:eof`     | Explicit end of input marker                             | (end)   |

  ## Example

  Tokenizing `:slack.divider` produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "divider", {1, 8}},
        {:eof, "", {1, 15}}
      ]

  Note: If there's a trailing newline, `:newline` appears before `:eof`.

  ## Token Types (Level 2)

  These tokens add support for attributes and default values
  (e.g., `:slack.header{text: "Hello"}` or `:slack.header "Hello"`):

  | Token           | Description                                | Example              |
  |-----------------|--------------------------------------------|--------------------- |
  | `:open_brace`   | Opening brace for attribute list           | `{`                  |
  | `:close_brace`  | Closing brace for attribute list           | `}`                  |
  | `:text`         | Quoted or unquoted text value              | `"Hello"`, `Hello`   |
  | `:whitespace`   | Spaces or tabs (not newlines)              | ` `, `\t`            |
  | `:comma`        | Separator between attributes               | `,`                  |
  | `:boolean`      | The literals `true` or `false`             | `true`               |
  | `:atom`         | Colon followed by identifier               | `:plain_text`        |
  | `:number`       | Numeric value (integer or float)           | `100`, `3.14`        |

  ### Termination rules for `:text`

  - **Quoted** (starts with `"`): continues until closing `"` (error if not found)
  - **Unquoted**: continues until `{`, `"`, or end of line

  ### Example 1 - Inline attributes with quoted text

  Tokenizing `:slack.header{text: "Hello", emoji: true}` produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "header", {1, 8}},
        {:open_brace, "{", {1, 14}},
        {:keyword, "text", {1, 15}},
        {:colon, ":", {1, 19}},
        {:whitespace, " ", {1, 20}},
        {:text, "\"Hello\"", {1, 21}},
        {:comma, ",", {1, 28}},
        {:whitespace, " ", {1, 29}},
        {:keyword, "emoji", {1, 30}},
        {:colon, ":", {1, 35}},
        {:whitespace, " ", {1, 36}},
        {:boolean, "true", {1, 37}},
        {:close_brace, "}", {1, 41}},
        {:eof, "", {1, 42}}
      ]

  ### Example 2 - Default value (quoted)

  Tokenizing `:slack.header "This is a header"` produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "header", {1, 8}},
        {:whitespace, " ", {1, 14}},
        {:text, "\"This is a header\"", {1, 15}},
        {:eof, "", {1, 35}}
      ]

  ### Example 3 - Default value (unquoted)

  Tokenizing `:slack.section This is a section` produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "section", {1, 8}},
        {:whitespace, " ", {1, 15}},
        {:text, "This is a section", {1, 16}},
        {:eof, "", {1, 33}}
      ]

  ### Example 4 - Unquoted default with inline attributes

  Tokenizing `:slack.section Some text{emoji: true}` produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "section", {1, 8}},
        {:whitespace, " ", {1, 15}},
        {:text, "Some text", {1, 16}},
        {:open_brace, "{", {1, 25}},
        {:keyword, "emoji", {1, 26}},
        {:colon, ":", {1, 31}},
        {:whitespace, " ", {1, 32}},
        {:boolean, "true", {1, 33}},
        {:close_brace, "}", {1, 37}},
        {:eof, "", {1, 38}}
      ]

  ## Token Types (Level 4)

  These tokens add support for multi-line elements with indentation:

  | Token     | Description                                          | Example |
  |-----------|------------------------------------------------------|---------|
  | `:indent` | Line starts with more whitespace than previous level | `  `    |
  | `:dedent` | Line starts with less whitespace than previous level | (empty) |

  ### Rules

  - The tokenizer tracks an indent stack to determine when to emit `:indent` / `:dedent`
  - `:indent` value contains the whitespace characters for that level (for error messages about mixed tabs/spaces)
  - `:dedent` value is empty - emitted once per level decreased
  - Multiple `:dedent` tokens are emitted when jumping back multiple levels
  - Lines at the same indent level emit neither `:indent` nor `:dedent`

  ### Example 1 - Simple indent

  Tokenizing:

      :slack.header
        text: "This is a header"

  Produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "header", {1, 8}},
        {:newline, "\n", {1, 14}},
        {:indent, "  ", {2, 1}},
        {:keyword, "text", {2, 3}},
        {:colon, ":", {2, 7}},
        {:whitespace, " ", {2, 8}},
        {:text, "\"This is a header\"", {2, 9}},
        {:dedent, "", {2, 29}},
        {:eof, "", {2, 29}}
      ]

  ### Example 2 - Multiple attributes at same level

  Tokenizing:

      :slack.header
        text: "Hello"
        emoji: true

  Produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "header", {1, 8}},
        {:newline, "\n", {1, 14}},
        {:indent, "  ", {2, 1}},
        {:keyword, "text", {2, 3}},
        {:colon, ":", {2, 7}},
        {:whitespace, " ", {2, 8}},
        {:text, "\"Hello\"", {2, 9}},
        {:newline, "\n", {2, 16}},
        {:keyword, "emoji", {3, 3}},
        {:colon, ":", {3, 8}},
        {:whitespace, " ", {3, 9}},
        {:boolean, "true", {3, 10}},
        {:dedent, "", {3, 14}},
        {:eof, "", {3, 14}}
      ]

  Note: No `:indent` or `:dedent` between lines 2 and 3 since they're at the same level.

  ### Example 3 - Nested indentation with multi-level dedent

  Tokenizing:

      :slack.section
        accessory:
          :image
            url: "https://..."
      :slack.divider

  Produces:

      [
        {:colon, ":", {1, 1}},
        {:keyword, "slack", {1, 2}},
        {:dot, ".", {1, 7}},
        {:keyword, "section", {1, 8}},
        {:newline, "\n", {1, 15}},
        {:indent, "  ", {2, 1}},
        {:keyword, "accessory", {2, 3}},
        {:colon, ":", {2, 12}},
        {:newline, "\n", {2, 13}},
        {:indent, "    ", {3, 1}},
        {:colon, ":", {3, 5}},
        {:keyword, "image", {3, 6}},
        {:newline, "\n", {3, 11}},
        {:indent, "      ", {4, 1}},
        {:keyword, "url", {4, 7}},
        {:colon, ":", {4, 10}},
        {:whitespace, " ", {4, 11}},
        {:text, "\"https://...\"", {4, 12}},
        {:newline, "\n", {4, 25}},
        {:dedent, "", {5, 1}},
        {:dedent, "", {5, 1}},
        {:dedent, "", {5, 1}},
        {:colon, ":", {5, 1}},
        {:keyword, "slack", {5, 2}},
        {:dot, ".", {5, 7}},
        {:keyword, "divider", {5, 8}},
        {:eof, "", {5, 15}}
      ]

  Note: Three `:dedent` tokens are emitted when going from level 3 back to level 0.

  ## Template Examples

  The following examples show templates and their expected parsed output (after parsing, not tokenizing):

  Every token in the list follows is a Tuple in the form of:
    {:platform, :element_type, [attribute_keyword_list]}

  Here are some examples of templates and the resulting tokens:

  :slack.divider
  -> {:slack, :divider, []}

  :slack.header{text: "This is a header"}
  -> {:slack, :header, [text: "This is a header"]}

  :slack.header "This is a header"
  -> {:slack, :header, [text: "This is a header"]}

  :slack.header
    text: "This is a header"
  -> {:slack, :header, [text: "This is a header"]}

  :slack.header
    text: "This is a header"
    verbatium: true
  -> {:slack, :header, [text: "This is a header", verbatium: true]}

  :slack.section "This is a section"
    accessory:
      :image{image_url: "https://...", alt_text: "An image"}
  ->
    {:slack, :section, [text: "This is a section"]}
    {:slack, {:cont, 0}, {:acessory, []}}
    {:slack, {:cont, 1}, {:image, [image_url: "...", alt_text: "An image"]}}

  :slack.section The pressing items you have in front of you and who may be waiting on you
    accessory:
      :overflow
        options:
          text: "*plain_text option 0*", value: "value-0"
          text: "*plain_text option 1*", value: "value-1"
        action_id: "overflow1234"
  ->
    {:slack, :section, [
      text: "The pressing items you have in front of you and who may be waiting on you"
      accessory: [type: :overflow, options: [
        %{text: %{type: "plain_text", text: "*plain_text option 0*"}, value: "value-0"},
        %{text: %{type: "plain_text", text: "*plain_text option 1*"}, value: "value-1"}
      ],
      action_id: "overflow1234"
    ]}

  {
    "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "The pressing items you have in front of you and who may be waiting on you"
    },
    "accessory": {
      "type": "overflow",
      "options": [
        {
          "text": {
          "type": "plain_text",
          "text": "*plain_text option 0*",
          "emoji": true
          },
          "value": "value-0"
        },
        {
            "text": {
            "type": "plain_text",
            "text": "*plain_text option 1*",
            "emoji": true
          },
          "value": "value-1"
        }]
      "action_id": "overflow1234"
    }
  }

  The Tokenizer must start with a platform line, such as `:slack`, to determine the appropriate tokenizer to use.

  Once this platform Tokenizer is established, the tokenizer can verify that the platform can parse the lines and
  determine defaults for attributes as needed.
  """

  def tokenize(template, _opts \\ []) when is_binary(template) do
    template
    |> String.to_charlist()
    |> do_tokenize({1, 1}, [])
    |> Enum.reverse()
  end

  # End of input - emit :eof
  defp do_tokenize([], pos, tokens) do
    [{:eof, "", pos} | tokens]
  end

  # Colon character
  defp do_tokenize([?: | rest], {line, col}, tokens) do
    do_tokenize(rest, {line, col + 1}, [{:colon, ":", {line, col}} | tokens])
  end

  # Dot character
  defp do_tokenize([?. | rest], {line, col}, tokens) do
    do_tokenize(rest, {line, col + 1}, [{:dot, ".", {line, col}} | tokens])
  end

  # Newline character
  defp do_tokenize([?\n | rest], {line, col}, tokens) do
    do_tokenize(rest, {line + 1, 1}, [{:newline, "\n", {line, col}} | tokens])
  end

  # Open brace
  defp do_tokenize([?{ | rest], {line, col}, tokens) do
    do_tokenize(rest, {line, col + 1}, [{:open_brace, "{", {line, col}} | tokens])
  end

  # Close brace
  defp do_tokenize([?} | rest], {line, col}, tokens) do
    do_tokenize(rest, {line, col + 1}, [{:close_brace, "}", {line, col}} | tokens])
  end

  # Comma
  defp do_tokenize([?, | rest], {line, col}, tokens) do
    do_tokenize(rest, {line, col + 1}, [{:comma, ",", {line, col}} | tokens])
  end

  # Quoted text
  defp do_tokenize([?" | _] = chars, {line, col}, tokens) do
    {text, rest} = take_quoted_text(chars, [])
    text_str = to_string(text)
    new_col = col + length(text)
    do_tokenize(rest, {line, new_col}, [{:text, text_str, {line, col}} | tokens])
  end

  # Whitespace (spaces and tabs)
  defp do_tokenize([c | _] = chars, {line, col}, tokens) when c == ?\s or c == ?\t do
    {whitespace, rest} = take_whitespace(chars, [])
    whitespace_str = to_string(whitespace)
    new_col = col + length(whitespace)
    do_tokenize(rest, {line, new_col}, [{:whitespace, whitespace_str, {line, col}} | tokens])
  end

  # Keyword (alphanumeric and underscores) - also handles booleans
  defp do_tokenize([c | _] = chars, {line, col}, tokens)
       when c in ?a..?z or c in ?A..?Z or c == ?_ do
    {keyword, rest} = take_keyword(chars, [])
    keyword_str = to_string(keyword)
    new_col = col + length(keyword)

    token_type =
      case keyword_str do
        "true" -> :boolean
        "false" -> :boolean
        _ -> :keyword
      end

    do_tokenize(rest, {line, new_col}, [{token_type, keyword_str, {line, col}} | tokens])
  end

  # Unexpected character - raise error
  defp do_tokenize([c | _rest], {line, col}, _tokens) do
    raise Juvet.Template.TokenizerError,
          "Unexpected character '#{<<c::utf8>>}' at line #{line}, column #{col}"
  end

  # Collect keyword characters (alphanumeric and underscores)
  defp take_keyword([c | rest], acc) when c in ?a..?z or c in ?A..?Z or c in ?0..?9 or c == ?_ do
    take_keyword(rest, [c | acc])
  end

  defp take_keyword(rest, acc) do
    {Enum.reverse(acc), rest}
  end

  # Collect whitespace characters (spaces and tabs)
  defp take_whitespace([c | rest], acc) when c == ?\s or c == ?\t do
    take_whitespace(rest, [c | acc])
  end

  defp take_whitespace(rest, acc) do
    {Enum.reverse(acc), rest}
  end

  # Collect quoted text (including the quotes)
  defp take_quoted_text([?" | rest], []) do
    take_quoted_text(rest, [?"])
  end

  defp take_quoted_text([?" | rest], acc) do
    {Enum.reverse([?" | acc]), rest}
  end

  defp take_quoted_text([c | rest], acc) do
    take_quoted_text(rest, [c | acc])
  end
end
