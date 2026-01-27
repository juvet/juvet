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
    +--> Compiler.Slack.compile/1   (platform: :slack)  --> {"blocks":[...]}
    +--> Compiler.Discord.compile/1 (platform: :discord)  # future
    +--> etc.
```

### File Structure

```
lib/juvet/template/
  compiler.ex                      # Main entry, dispatches by platform
  compiler/
    encoder.ex                     # Encoder behaviour (defaults to Poison)
    encoder/
      helpers.ex                   # Shared utilities (maybe_put/3)
    slack.ex                       # Compiler.Slack - wraps in {"blocks":[...]}
    slack/
      blocks/
        actions.ex                 # Compiler.Slack.Blocks.Actions
        context.ex                 # Compiler.Slack.Blocks.Context
        divider.ex                 # Compiler.Slack.Blocks.Divider
        header.ex                  # Compiler.Slack.Blocks.Header
        image.ex                   # Compiler.Slack.Blocks.Image
        section.ex                 # Compiler.Slack.Blocks.Section
      elements/
        button.ex                  # Compiler.Slack.Elements.Button
      objects/
        text.ex                    # Compiler.Slack.Objects.Text
```

### Compiler.compile/1

- Takes AST (list of element maps)
- Returns JSON string
- Delegates to platform-specific compiler based on `platform:` field

### Platform Compilers (e.g., Compiler.Slack)

- `compile/1` - Takes list of AST elements, returns JSON string with platform-specific wrapper
- Delegates to block modules (e.g., `Blocks.Header.compile/1`)
- Block modules return Elixir maps, platform compiler encodes to JSON

### Slack Block Kit Hierarchy

Following Slack's Block Kit structure:
- **Blocks** - Top-level layout (header, divider, section, actions)
- **Elements** - Interactive components nested in blocks (button, image)
- **Objects** - Composition objects (text objects: plain_text, mrkdwn)

## Compiler Transformations

The compiler applies platform-specific transformations when converting AST to JSON.

### Slack Block Kit Transformations

#### Element Type Mapping

| AST Element | JSON Type |
|-------------|-----------|
| `:header` | `"header"` |
| `:divider` | `"divider"` |
| `:section` | `"section"` |
| `:context` | `"context"` |
| `:image` | `"image"` |
| `:button` | `"button"` |
| `:actions` | `"actions"` |

#### Text Object Wrapping

Text attributes are wrapped in text objects based on element type:

- **header**: `text` → `{"type": "plain_text", "text": "...", "emoji": true/false}`
- **section**: `text` → `{"type": "mrkdwn", "text": "..."}`
- **section fields**: each field → `{"type": "mrkdwn", "text": "..."}`
- **context**: each element → `{"type": "mrkdwn", "text": "..."}` or image object
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
  alias Juvet.Template.Compiler.Slack

  def compile([]), do: ""
  def compile([%{platform: :slack} | _] = ast), do: Slack.compile(ast)
end

# lib/juvet/template/compiler/encoder.ex
defmodule Juvet.Template.Compiler.Encoder do
  @moduledoc """
  Encoder behaviour for JSON encoding.

  Defaults to Poison. Configure a different encoder via:

      config :juvet, :json_encoder, Jason
  """

  @callback encode!(term()) :: String.t()

  def encode!(data) do
    encoder().encode!(data)
  end

  defp encoder do
    Application.get_env(:juvet, :json_encoder, Poison)
  end
end

# lib/juvet/template/compiler/encoder/helpers.ex
defmodule Juvet.Template.Compiler.Encoder.Helpers do
  def maybe_put(%{} = map, _key, nil), do: map
  def maybe_put(%{} = map, key, value), do: Map.put(map, key, value)
end

# lib/juvet/template/compiler/slack.ex
defmodule Juvet.Template.Compiler.Slack do
  alias Juvet.Template.Compiler.Encoder

  def compile([]), do: Encoder.encode!(%{blocks: []})

  def compile(ast) do
    %{blocks: Enum.map(ast, &compile_element/1)}
    |> Encoder.encode!()
  end

  def compile_element(%{element: :divider} = el), do: Divider.compile(el)
  def compile_element(%{element: :header} = el), do: Header.compile(el)
  # ... other elements
end

# lib/juvet/template/compiler/slack/blocks/header.ex
defmodule Juvet.Template.Compiler.Slack.Blocks.Header do
  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :header, attributes: %{text: text} = attrs}) do
    %{type: "header", text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))}
  end
end

# lib/juvet/template/compiler/slack/objects/text.ex
defmodule Juvet.Template.Compiler.Slack.Objects.Text do
  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(text, %{type: :plain_text} = attrs) do
    %{type: "plain_text", text: text}
    |> maybe_put(:emoji, attrs[:emoji])
  end

  def compile(text, %{type: :mrkdwn} = attrs) do
    %{type: "mrkdwn", text: text}
    |> maybe_put(:verbatim, attrs[:verbatim])
  end

  def compile(text, attrs), do: compile(text, Map.put(attrs, :type, :mrkdwn))
end
```

### Phase 1: Basic structure and divider

Compiler.Slack wraps elements in `{"blocks":[...]}` and compiles divider:

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

### Context block

The context block displays message context (images and text) in a smaller format.

```elixir
# Input AST
[%{
  platform: :slack,
  element: :context,
  attributes: %{},
  children: %{
    elements: [
      %{platform: :slack, element: :image, attributes: %{url: "http://example.com/avatar.png", alt_text: "User"}},
      %{platform: :slack, element: :text, attributes: %{text: "Posted by Alice", type: :mrkdwn}}
    ]
  }
}]

# Output JSON
{
  "blocks": [{
    "type": "context",
    "elements": [
      {"type": "image", "image_url": "http://example.com/avatar.png", "alt_text": "User"},
      {"type": "mrkdwn", "text": "Posted by Alice"}
    ]
  }]
}
```

Context elements can be:
- **image** - rendered as image object (not image block)
- **text** - rendered as text object (mrkdwn or plain_text)

### Section with fields

Sections can display multiple fields in a two-column layout.

```elixir
# Input AST
[%{
  platform: :slack,
  element: :section,
  attributes: %{text: "Order Details"},
  children: %{
    fields: [
      %{platform: :slack, element: :text, attributes: %{text: "*Order ID*\n12345"}},
      %{platform: :slack, element: :text, attributes: %{text: "*Status*\nShipped"}}
    ]
  }
}]

# Output JSON
{
  "blocks": [{
    "type": "section",
    "text": {"type": "mrkdwn", "text": "Order Details"},
    "fields": [
      {"type": "mrkdwn", "text": "*Order ID*\n12345"},
      {"type": "mrkdwn", "text": "*Status*\nShipped"}
    ]
  }]
}
```

Fields are always rendered as mrkdwn text objects. Maximum of 10 fields per section.

## Future: Compile-Time Template Compilation

For optimal performance, templates can be compiled at compile-time rather than runtime. This approach is similar to how Phoenix templates and EEx work.

### Current Runtime Flow

```
# Every request
Template → Tokenizer → Parser → Compiler → JSON with <%= %> → EEx.eval_string → Final output
```

### Proposed Compile-Time Flow

```
# At compile time (once)
Template → Tokenizer → Parser → Compiler → JSON with <%= %> markers (stored as module attribute)

# At runtime (every request)
Stored JSON + bindings → EEx.eval_string → Final output
```

### Implementation Approach

1. **Define templates in modules** using a macro:

```elixir
defmodule MyApp.Templates.Welcome do
  use Juvet.Template

  template :welcome, """
  :slack.header{text: "Hello <%= name %>"}
  :slack.divider
  :slack.section "Welcome to <%= team %>!"
  """
end
```

2. **Compile at build time** - the macro compiles the template to JSON:

```elixir
defmacro template(name, source) do
  # Compile template to JSON at macro expansion time
  json = source
    |> Juvet.Template.Tokenizer.tokenize()
    |> Juvet.Template.Parser.parse()
    |> Juvet.Template.Compiler.compile()

  quote do
    def unquote(name)(bindings) do
      EEx.eval_string(unquote(json), bindings)
    end
  end
end
```

3. **Call at runtime** with only bindings evaluation:

```elixir
MyApp.Templates.Welcome.welcome(name: "Alice", team: "Acme")
# => {"blocks":[{"type":"header","text":{"type":"plain_text","text":"Hello Alice"}},...]}
```

### Benefits

- **Faster rendering** - tokenizing, parsing, and compiling happen once at build time
- **Early error detection** - syntax errors caught at compile time, not runtime
- **Smaller memory footprint** - no need to store raw template strings

### Considerations

- Templates with dynamic structure (conditionals, loops) may need special handling
- Error messages should reference original template line numbers
- Hot code reloading should recompile templates in development
