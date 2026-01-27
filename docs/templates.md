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

## Future: Additional Block Kit Components

The following Slack Block Kit components are planned for future implementation.

### Blocks

#### Input Block

Collects user input in modals and workflow steps.

```elixir
# Input AST
[%{
  platform: :slack,
  element: :input,
  attributes: %{label: "Your Name", optional: false},
  children: %{
    element: %{platform: :slack, element: :plain_text_input, attributes: %{action_id: "name_input"}}
  }
}]

# Output JSON
{
  "blocks": [{
    "type": "input",
    "label": {"type": "plain_text", "text": "Your Name"},
    "optional": false,
    "element": {"type": "plain_text_input", "action_id": "name_input"}
  }]
}
```

### Elements

#### Select Menus

Static select, user select, conversation select, channel select.

```elixir
# Static select
%{platform: :slack, element: :static_select, attributes: %{
  placeholder: "Choose an option",
  action_id: "select_1"
}, children: %{
  options: [
    %{platform: :slack, element: :option, attributes: %{text: "Option 1", value: "opt_1"}},
    %{platform: :slack, element: :option, attributes: %{text: "Option 2", value: "opt_2"}}
  ]
}}

# Output JSON
{
  "type": "static_select",
  "placeholder": {"type": "plain_text", "text": "Choose an option"},
  "action_id": "select_1",
  "options": [
    {"text": {"type": "plain_text", "text": "Option 1"}, "value": "opt_1"},
    {"text": {"type": "plain_text", "text": "Option 2"}, "value": "opt_2"}
  ]
}
```

#### Overflow Menu

Compact menu for additional actions.

```elixir
%{platform: :slack, element: :overflow, attributes: %{action_id: "overflow_1"}, children: %{
  options: [
    %{platform: :slack, element: :option, attributes: %{text: "Edit", value: "edit"}},
    %{platform: :slack, element: :option, attributes: %{text: "Delete", value: "delete"}}
  ]
}}
```

#### Checkboxes

Multi-select with checkboxes.

```elixir
%{platform: :slack, element: :checkboxes, attributes: %{action_id: "checkboxes_1"}, children: %{
  options: [
    %{platform: :slack, element: :option, attributes: %{text: "Email notifications", value: "email"}},
    %{platform: :slack, element: :option, attributes: %{text: "SMS notifications", value: "sms"}}
  ]
}}
```

#### Radio Buttons

Single-select with radio buttons.

```elixir
%{platform: :slack, element: :radio_buttons, attributes: %{action_id: "radio_1"}, children: %{
  options: [
    %{platform: :slack, element: :option, attributes: %{text: "Small", value: "sm"}},
    %{platform: :slack, element: :option, attributes: %{text: "Medium", value: "md"}},
    %{platform: :slack, element: :option, attributes: %{text: "Large", value: "lg"}}
  ]
}}
```

#### Date and Time Pickers

```elixir
# Date picker
%{platform: :slack, element: :datepicker, attributes: %{
  action_id: "date_1",
  initial_date: "2024-01-15",
  placeholder: "Select a date"
}}

# Time picker
%{platform: :slack, element: :timepicker, attributes: %{
  action_id: "time_1",
  initial_time: "09:00",
  placeholder: "Select a time"
}}

# Datetime picker
%{platform: :slack, element: :datetimepicker, attributes: %{
  action_id: "datetime_1",
  initial_date_time: 1672531200
}}
```

#### Plain Text Input

Text input for modals.

```elixir
%{platform: :slack, element: :plain_text_input, attributes: %{
  action_id: "input_1",
  placeholder: "Enter text here",
  multiline: false
}}
```

### Objects

#### Confirmation Dialog

Confirmation popup for destructive actions.

```elixir
# Button with confirmation
%{platform: :slack, element: :button, attributes: %{
  text: "Delete",
  action_id: "delete_btn",
  style: :danger
}, children: %{
  confirm: %{
    platform: :slack,
    element: :confirm,
    attributes: %{
      title: "Are you sure?",
      text: "This action cannot be undone.",
      confirm: "Delete",
      deny: "Cancel"
    }
  }
}}

# Output JSON
{
  "type": "button",
  "text": {"type": "plain_text", "text": "Delete"},
  "action_id": "delete_btn",
  "style": "danger",
  "confirm": {
    "title": {"type": "plain_text", "text": "Are you sure?"},
    "text": {"type": "plain_text", "text": "This action cannot be undone."},
    "confirm": {"type": "plain_text", "text": "Delete"},
    "deny": {"type": "plain_text", "text": "Cancel"}
  }
}
```

#### Option and Option Group

Used in select menus, checkboxes, radio buttons.

```elixir
# Option
%{platform: :slack, element: :option, attributes: %{
  text: "Option Label",
  value: "option_value",
  description: "Optional description"
}}

# Option Group (for categorizing options)
%{platform: :slack, element: :option_group, attributes: %{label: "Category"}, children: %{
  options: [
    %{platform: :slack, element: :option, attributes: %{text: "Option 1", value: "opt_1"}}
  ]
}}
```

### Implementation Priority

| Priority | Component | Notes |
|----------|-----------|-------|
| High | Input block | Required for modals |
| High | Static select | Common interactive element |
| High | Plain text input | Required for forms |
| Medium | Confirmation dialog | Important for destructive actions |
| Medium | Overflow menu | Common UX pattern |
| Medium | Checkboxes | Multi-select scenarios |
| Medium | Radio buttons | Single-select scenarios |
| Medium | Option/Option group | Required by select menus |
| Lower | Date/time pickers | Scheduling use cases |
| Lower | User/channel selects | Slack-specific pickers |
