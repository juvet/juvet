# Juvet Templates

Working design document for the Juvet template system.

## Pipeline Overview

```
Template (string)
    |
    v
Tokenizer.tokenize/1
    |
    v
Tokens (list of {type, value, {line, col}})
    |
    v
Parser.parse/1
    |
    v
AST (list of element maps)
    |
    v
Compiler.compile/1
    |
    v
JSON string (for Slack Block Kit, etc.)
    |
    v
Renderer.eval/2
    |
    v
Final output (with EEx bindings applied)
```

## Token Format

Tokens are tuples: `{type, value, {line, col}}`

Types: `:colon`, `:keyword`, `:dot`, `:newline`, `:eof`, `:open_brace`, `:close_brace`,
`:text`, `:whitespace`, `:comma`, `:boolean`, `:atom`, `:number`, `:indent`, `:dedent`

## AST Format

Each element becomes a map:

```elixir
%{
  platform: :slack,
  element: :header,
  attributes: %{text: "Hello", emoji: true},
  children: %{...}   # nested elements keyed by attribute name (optional)
}
```

## JSON Output Format

The Compiler transforms the AST into JSON for the target platform.
For Slack Block Kit, the final JSON looks like:

```json
{
  "blocks": [
    {"type": "header", "text": {"type": "plain_text", "text": "Hello", "emoji": true}},
    {"type": "divider"},
    {"type": "section", "text": {"type": "mrkdwn", "text": "Content"}}
  ]
}
```

## Compiler Architecture

The compiler delegates to platform-specific compilers based on the `platform:` field in each AST element.

```
Compiler.compile/1
    |
    v
Group elements by platform
    |
    v
Delegate to platform compiler:
    |
    +--> SlackCompiler.compile/1   (platform: :slack)  --> {"blocks":[...]}
    +--> DiscordCompiler.compile/1 (platform: :discord)  # future
    +--> etc.
```

### File Structure

```
lib/juvet/template/
  compiler.ex              # Main entry, dispatches by platform
  compiler/
    slack_compiler.ex      # Handles :slack elements, wraps in {"blocks":[...]}
```

### Compiler.compile/1

- Takes AST (list of element maps)
- Returns JSON string
- Delegates to platform-specific compiler (currently assumes single platform per template)

### Platform Compilers

Each platform compiler implements:

- `compile/1` - Takes list of AST elements, returns JSON string with platform-specific wrapper
- `compile_element/1` - Compiles a single element to an Elixir map

## Compiler Transformations

The compiler applies platform-specific transformations when converting AST to JSON.

### Slack Block Kit Transformations

#### Element Type Mapping

| AST Element | JSON Type |
|-------------|-----------|
| `:header` | `"header"` |
| `:divider` | `"divider"` |
| `:section` | `"section"` |
| `:image` | `"image"` |
| `:button` | `"button"` |
| `:actions` | `"actions"` |

#### Text Object Wrapping

Text attributes are wrapped in text objects based on element type:

- **header**: `text` → `{"type": "plain_text", "text": "...", "emoji": true/false}`
- **section**: `text` → `{"type": "mrkdwn", "text": "..."}`
- **button**: `text` → `{"type": "plain_text", "text": "..."}`

#### Attribute Renaming

Some attributes are renamed for Slack compatibility:

- `url` in image → `image_url`

#### Children Handling

- Single child (e.g., `accessory`) → compiled and added as attribute
- List children (e.g., `elements`) → each child compiled, added as array

## Grammar (informal)

```
template     -> element* eof
element      -> colon keyword dot keyword element_body?
element_body -> default_value? inline_attrs? (newline block)?
default_value -> whitespace text
inline_attrs -> open_brace attr_list close_brace
attr_list    -> (attr (comma attr)*)?
attr         -> whitespace? keyword colon whitespace? value
value        -> text | boolean | atom | number
block        -> indent (attr | element)+ dedent
```

## End-to-End Example

### Input Template

```
:slack.header{text: "Welcome", emoji: true}
:slack.divider
:slack.section "Click a button below"
```

### After Tokenizer (simplified)

```elixir
[
  {:colon, ":", _}, {:keyword, "slack", _}, {:dot, ".", _}, {:keyword, "header", _},
  {:open_brace, "{", _}, {:keyword, "text", _}, {:colon, ":", _}, ...
  {:eof, "", _}
]
```

### After Parser (AST)

```elixir
[
  %{platform: :slack, element: :header, attributes: %{text: "Welcome", emoji: true}},
  %{platform: :slack, element: :divider, attributes: %{}},
  %{platform: :slack, element: :section, attributes: %{text: "Click a button below"}}
]
```

### After Compiler (JSON string)

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {"type": "plain_text", "text": "Welcome", "emoji": true}
    },
    {"type": "divider"},
    {
      "type": "section",
      "text": {"type": "mrkdwn", "text": "Click a button below"}
    }
  ]
}
```

## Parser Examples by Phase

### Phase 1: Basic element parsing (no attributes)

```
Input:  ""
Output: []

Input:  ":slack.divider"
AST:    [%{platform: :slack, element: :divider, attributes: %{}}]
JSON:   {"blocks": [{"type": "divider"}]}
```

### Phase 2: Inline attributes

```
Input:  ":slack.header{text: \"Hello\", emoji: true}"
AST:    [%{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}]
JSON:   {"blocks": [{"type": "header", "text": {"type": "plain_text", "text": "Hello", "emoji": true}}]}
```

### Phase 3: Default values

```
Input:  ":slack.header \"Hello\""
AST:    [%{platform: :slack, element: :header, attributes: %{text: "Hello"}}]
JSON:   {"blocks": [{"type": "header", "text": {"type": "plain_text", "text": "Hello"}}]}
```

### Phase 4: Multi-line with indent/dedent

```
Input:
  :slack.header
    text: "Hello"
    emoji: true

AST: [%{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}]
JSON: {"blocks": [{"type": "header", "text": {"type": "plain_text", "text": "Hello", "emoji": true}}]}
```

### Phase 5: Nested elements (single child)

```
Input:
  :slack.section
    text: "Main content"
    accessory:
      :slack.image
        url: "https://example.com/img.png"
        alt_text: "Example"

AST: [
  %{
    platform: :slack,
    element: :section,
    attributes: %{text: "Main content"},
    children: %{
      accessory: %{
        platform: :slack,
        element: :image,
        attributes: %{url: "https://example.com/img.png", alt_text: "Example"}
      }
    }
  }
]

JSON: {
  "blocks": [{
    "type": "section",
    "text": {"type": "mrkdwn", "text": "Main content"},
    "accessory": {
      "type": "image",
      "image_url": "https://example.com/img.png",
      "alt_text": "Example"
    }
  }]
}
```

### Phase 6: Multiple top-level elements

```
Input:
  :slack.header{text: "Welcome"}
  :slack.divider
  :slack.section "Main content"

AST: [
  %{platform: :slack, element: :header, attributes: %{text: "Welcome"}},
  %{platform: :slack, element: :divider, attributes: %{}},
  %{platform: :slack, element: :section, attributes: %{text: "Main content"}}
]

JSON: {
  "blocks": [
    {"type": "header", "text": {"type": "plain_text", "text": "Welcome"}},
    {"type": "divider"},
    {"type": "section", "text": {"type": "mrkdwn", "text": "Main content"}}
  ]
}
```

### Phase 7: List children (e.g., actions with multiple buttons)

```
Input:
  :slack.actions
    elements:
      :slack.button
        text: "Button 1"
        action_id: "btn_1"
      :slack.button
        text: "Button 2"
        action_id: "btn_2"

AST: [
  %{
    platform: :slack,
    element: :actions,
    attributes: %{},
    children: %{
      elements: [
        %{platform: :slack, element: :button, attributes: %{text: "Button 1", action_id: "btn_1"}},
        %{platform: :slack, element: :button, attributes: %{text: "Button 2", action_id: "btn_2"}}
      ]
    }
  }
]

JSON: {
  "blocks": [{
    "type": "actions",
    "elements": [
      {"type": "button", "text": {"type": "plain_text", "text": "Button 1"}, "action_id": "btn_1"},
      {"type": "button", "text": {"type": "plain_text", "text": "Button 2"}, "action_id": "btn_2"}
    ]
  }]
}
```

## Compiler Implementation Phases

### Phase 0: Architecture setup

Create the compiler structure with platform delegation:

```elixir
# lib/juvet/template/compiler.ex
defmodule Juvet.Template.Compiler do
  alias Juvet.Template.Compiler.SlackCompiler

  def compile([]), do: ""

  def compile([%{platform: :slack} | _] = ast) do
    SlackCompiler.compile(ast)
  end
end

# lib/juvet/template/compiler/slack_compiler.ex
defmodule Juvet.Template.Compiler.SlackCompiler do
  def compile([]), do: ~s({"blocks":[]})

  def compile(ast) do
    blocks = Enum.map(ast, &compile_element/1)
    ~s({"blocks":[#{Enum.join(blocks, ",")}]})
  end

  def compile_element(%{element: element_type} = el) do
    # dispatch by element type, return Elixir map
  end
end
```

### Phase 1: Basic structure and divider (SlackCompiler)

SlackCompiler wraps elements in `{"blocks":[...]}` and compiles divider:

```elixir
# Input AST
[%{platform: :slack, element: :divider, attributes: %{}}]

# Output JSON
{"blocks":[{"type":"divider"}]}
```

### Phase 2: Header with text (plain_text wrapping)

```elixir
# Input AST
[%{platform: :slack, element: :header, attributes: %{text: "Hello"}}]

# Output JSON
{"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello"}}]}

# With emoji attribute
[%{platform: :slack, element: :header, attributes: %{text: "Hello", emoji: true}}]

# Output JSON
{"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello","emoji":true}}]}
```

### Phase 3: Section with text (mrkdwn wrapping)

```elixir
# Input AST
[%{platform: :slack, element: :section, attributes: %{text: "Hello *world*"}}]

# Output JSON
{"blocks":[{"type":"section","text":{"type":"mrkdwn","text":"Hello *world*"}}]}
```

### Phase 4: Image element (attribute renaming)

```elixir
# Input AST
[%{platform: :slack, element: :image, attributes: %{url: "http://example.com/img.png", alt_text: "Example"}}]

# Output JSON
{"blocks":[{"type":"image","image_url":"http://example.com/img.png","alt_text":"Example"}]}
```

### Phase 5: Nested children (section with accessory)

```elixir
# Input AST
[%{
  platform: :slack,
  element: :section,
  attributes: %{text: "Content"},
  children: %{
    accessory: %{platform: :slack, element: :image, attributes: %{url: "http://ex.com/img.png", alt_text: "Alt"}}
  }
}]

# Output JSON
{"blocks":[{"type":"section","text":{"type":"mrkdwn","text":"Content"},"accessory":{"type":"image","image_url":"http://ex.com/img.png","alt_text":"Alt"}}]}
```

### Phase 6: List children (actions with buttons)

```elixir
# Input AST
[%{
  platform: :slack,
  element: :actions,
  attributes: %{},
  children: %{
    elements: [
      %{platform: :slack, element: :button, attributes: %{text: "Click", action_id: "btn_1"}}
    ]
  }
}]

# Output JSON
{"blocks":[{"type":"actions","elements":[{"type":"button","text":{"type":"plain_text","text":"Click"},"action_id":"btn_1"}]}]}
```

### Phase 7: Multiple top-level elements

```elixir
# Input AST
[
  %{platform: :slack, element: :header, attributes: %{text: "Welcome"}},
  %{platform: :slack, element: :divider, attributes: %{}},
  %{platform: :slack, element: :section, attributes: %{text: "Content"}}
]

# Output JSON
{"blocks":[{"type":"header","text":{"type":"plain_text","text":"Welcome"}},{"type":"divider"},{"type":"section","text":{"type":"mrkdwn","text":"Content"}}]}
```

### Phase 8: Interpolation passthrough

EEx interpolation tags must pass through the entire pipeline intact until the final eval step.

```elixir
# Input Template
":slack.header{text: \"Hello <%= name %>\"}"

# After Tokenizer - interpolation preserved in text token
[..., {:text, "\"Hello <%= name %>\"", _}, ...]

# After Parser - interpolation preserved in AST
[%{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}}]

# After Compiler - interpolation preserved in JSON
{"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello <%= name %>"}}]}

# After Renderer.eval with [name: "World"]
{"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello World"}}]}
```

This ensures interpolation works end-to-end without requiring special handling in tokenizer, parser, or compiler.
