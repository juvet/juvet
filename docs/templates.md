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
Atom-keyed map (for Slack Block Kit, etc.)
    |
    v
Template layer (format option)
    |
    +--> format: :map (default) --> return map directly
    +--> format: :json          --> Encoder.encode!() --> JSON string
    |
    v
EEx interpolation at runtime (if dynamic)
    |
    v
Final output (map or JSON string with bindings applied)
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
  children: %{...},  # nested elements keyed by attribute name (optional)
  line: 1,           # source line number (1-indexed)
  column: 1          # source column number (1-indexed)
}
```

The `line` and `column` fields track where each element was defined in the original template source, enabling precise error messages during compilation.

## Compiler Output Format

The Compiler transforms the AST into atom-keyed maps for the target platform.
For Slack Block Kit, the compiled output looks like:

```elixir
%{
  type: "modal",
  blocks: [
    %{type: "header", text: %{type: "plain_text", text: "Hello", emoji: true}},
    %{type: "divider"},
    %{type: "section", text: %{type: "mrkdwn", text: "Content"}}
  ]
}
```

The template layer then either returns the map directly (`:map` format, the default)
or encodes it to JSON (`:json` format) via `Encoder.encode!/1`.

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
      view.ex                      # Compiler.Slack.View - view container
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
- Returns atom-keyed map
- Delegates to platform-specific compiler based on `platform:` field

### Platform Compilers (e.g., Compiler.Slack)

- `compile/1` - Takes list of AST elements, returns atom-keyed map with platform-specific wrapper
- Delegates to block modules (e.g., `Blocks.Header.compile/1`)
- Block modules return Elixir maps, platform compiler assembles them into a map

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
| `:view` | `"modal"`, `"home"` (from `type` attribute) |

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
element      -> full_element | short_element
full_element -> colon keyword dot keyword element_body?
short_element -> dot keyword element_body?       (valid inside a parent element, or at top level with file platform)
element_body -> default_value? inline_attrs? (newline block)?
default_value -> whitespace text
inline_attrs -> open_brace attr_list close_brace
attr_list    -> (attr (comma attr)*)?
attr         -> whitespace? keyword colon whitespace? value
value        -> text | boolean | atom | number
block        -> indent (attr | element)+ dedent
```

Short elements (`.element`) inherit their platform from the parent element.
They can only appear as children — using `.element` at the top level is an error,
unless a file-level platform is set (e.g., `.slack.cheex` files).

## Error Handling and Line Number Tracking

The template pipeline tracks source positions through all stages, enabling precise error messages that help developers quickly locate and fix issues.

### Error Types

#### Tokenizer.Error

Raised when the tokenizer encounters invalid syntax:

```elixir
%Juvet.Template.Tokenizer.Error{
  message: "Unterminated string",
  line: 3,
  column: 15
}
```

Common tokenizer errors:
- Unterminated strings (missing closing quote)
- Invalid characters

#### Parser.Error

Raised when tokens don't form a valid template structure:

```elixir
%Juvet.Template.Parser.Error{
  message: "Unexpected keyword 'invalid' at top level",
  line: 2,
  column: 1
}
```

Common parser errors:
- Unexpected tokens at top level
- Invalid element syntax (missing platform or element name)
- Unexpected tokens in attribute lists

#### Compiler Errors

Raised when the AST contains unknown elements:

```elixir
# Unknown element type
ArgumentError: Unknown Slack element: :nonexistent (line 1, column 1)
```

### Error Message Format

All errors include line and column information when available:

```
Error message (line N, column M)
```

For example:
```
Unterminated string (line 3, column 15)
Invalid element syntax, expected :platform.element (line 1, column 1)
Unknown Slack element: :unknown (line 2, column 1)
```

### Compile-Time Error Reporting

When using the `template/2` macro, errors are converted to `CompileError` with the template name and line number:

```elixir
defmodule MyTemplates do
  use Juvet.Template

  template :bad, ":slack.nonexistent{text: \"Hello\"}"
  # => ** (CompileError) template :bad failed to compile: Unknown Slack element: :nonexistent (line 1, column 1)
end
```

The `line` field in `CompileError` enables IDE integration, allowing editors to jump directly to the problematic line in the source file.

### Position Tracking Through the Pipeline

```
Template Source
    |
    v
Tokenizer: Each token includes {line, column}
    |
    v
Parser: AST elements include line and column from the opening colon
    |
    v
Compiler: Uses line/column for error messages about unknown elements
    |
    v
Template macro: Catches errors and re-raises as CompileError with line info
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

### Phase 8: Platform inheritance (`.element` shorthand)

Child elements can inherit their platform from the parent element using `.element` syntax instead of `:platform.element`. This is purely syntactic sugar — the AST always includes an explicit `platform:` field.

```
Input:
  :slack.view
    type: :modal
    blocks:
      .header{text: "Hello"}
      .divider
      .section "Welcome"

AST: [
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
```

Full and shorthand syntax can be mixed freely within the same block:

```
:slack.actions
  elements:
    :slack.button
      text: "Full syntax"
    .button
      text: "Shorthand"
```

Using `.element` at the top level (no parent) raises a parser error:

```
.header{text: "Hello"}
# => ** (Parser.Error) Element with '.' shorthand must be inside a parent element that specifies a platform
```

### Platform from Filename

Files named with a `.slack.cheex` extension establish a file-level platform, allowing `.element` shorthand at the top level — including for the root element.

**Before** (standard `.cheex`):
```
:slack.view
  type: :modal
  blocks:
    .header{text: "Hello"}
    .divider
```

**After** (`home.slack.cheex`):
```
.view
  type: :modal
  blocks:
    .header{text: "Hello"}
    .divider
```

```elixir
defmodule MyApp.Templates do
  use Juvet.Template

  template :home, file: "templates/home.slack.cheex"
end
```

**Naming convention:** The platform segment is the second-to-last part of the filename before `.cheex`:

| Filename | Platform |
|----------|----------|
| `home.slack.cheex` | `:slack` |
| `greeting.cheex` | none (standard) |
| `my.template.slack.cheex` | `:slack` |
| `home.discord.cheex` | none (`:discord` not yet recognized) |

Currently only `:slack` is recognized as a platform in filenames.

**Validation rules:**

- Using the matching full syntax (`:slack.header`) in a `.slack.cheex` file is allowed — it's just redundant
- Using a different platform (`:discord.header`) in a `.slack.cheex` file raises a compile-time error:
  ```
  ** (CompileError) platform :discord in template does not match file platform :slack (line 1, column 1)
  ```
- Inline templates (`template(:name, "source")`) are unaffected — no filename to extract from
- Partials from `.slack.cheex` files also support top-level shorthand

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

## Compile-Time Template Compilation

For optimal performance, templates can be compiled at compile-time rather than runtime. This approach is similar to how Phoenix templates and EEx work.

### Current Runtime Flow

```
# Every request
Template → Tokenizer → Parser → Compiler → Map with <%= %> → eval_map/EEx → Final output
```

### Compile-Time Flow

```
# At compile time (once)
Template → Tokenizer → Parser → Compiler → Map with <%= %> markers (stored in module)

# At runtime (every request, format: :map)
Stored map + bindings → eval_map → Final map output

# At runtime (every request, format: :json)
Stored JSON + bindings → EEx.eval_string → Final JSON string
```

### Target API

```elixir
defmodule MyApp.Templates.Welcome do
  use Juvet.Template

  template :welcome, """
  :slack.view
    type: :modal
    blocks:
      :slack.header{text: "Hello <%= name %>"}
      :slack.divider
      :slack.section "Welcome to <%= team %>!"
  """
end

# Usage (default format: :map)
MyApp.Templates.Welcome.welcome(name: "Alice", team: "Acme")
#=> %{type: "modal", blocks: [%{type: "header", text: %{type: "plain_text", text: "Hello Alice"}}, ...]}

# With format: :json
defmodule MyApp.Templates.Json do
  use Juvet.Template, format: :json

  template :welcome, """
  :slack.view
    type: :modal
    blocks:
      :slack.header{text: "Hello <%= name %>"}
  """
end

MyApp.Templates.Json.welcome(name: "Alice")
#=> "{\"type\":\"modal\",\"blocks\":[...]}"

# Per-template override
defmodule MyApp.Templates.Mixed do
  use Juvet.Template

  template :map_template, ":slack.view ..."
  template :json_template, ":slack.view ...", format: :json
end
```

### Benefits

- **Faster rendering** - tokenizing, parsing, and compiling happen once at build time
- **Early error detection** - syntax errors caught at compile time, not runtime
- **Smaller memory footprint** - no need to store raw template strings

### Implementation Phases

#### Phase 0: Basic `use` and `template/2` macro

Create `Juvet.Template` module with:
- `__using__/1` macro that imports the `template` macro and accepts a `format:` option
- `template/2` and `template/3` macros that compile templates at compile-time and generate functions

```elixir
defmodule Juvet.Template do
  defmacro __using__(opts) do
    format = Keyword.get(opts, :format, :map)

    quote do
      import Juvet.Template, only: [template: 2, template: 3]
      Module.put_attribute(__MODULE__, :juvet_template_format, unquote(format))
    end
  end

  defmacro template(name, source) do
    format = Module.get_attribute(__CALLER__.module, :juvet_template_format)
    # Compile template to map at macro expansion time
    compiled = source
      |> Juvet.Template.Tokenizer.tokenize()
      |> Juvet.Template.Parser.parse()
      |> Juvet.Template.Compiler.compile()

    generate_template_function(name, compiled, format)
  end
end
```

**Test:**

```elixir
defmodule MyApp.WelcomeTemplate do
  use Juvet.Template

  template :welcome, ":slack.view\n  type: :modal\n  blocks:\n    :slack.header{text: \"Hello <%= name %>\"}"
end

MyApp.WelcomeTemplate.welcome(name: "World")
#=> %{type: "modal", blocks: [%{type: "header", text: %{type: "plain_text", text: "Hello World"}}]}
```

#### Phase 1: No-bindings optimization

Skip runtime evaluation when there are no interpolations in the template.

For `:map` format: if the compiled map contains no `<%` markers, return the map literal directly via `Macro.escape/1`. Otherwise, use `eval_map/2` at runtime to walk the map and evaluate EEx in string values.

For `:json` format: if the compiled JSON string contains no `<%` markers, return the string directly. Otherwise, use `EEx.eval_string/2` at runtime.

```elixir
defp generate_template_function(name, compiled, :map) do
  escaped = Macro.escape(compiled)

  if map_contains_eex?(compiled) do
    quote do
      def unquote(name)(bindings \\ []) do
        Juvet.Template.eval_map(unquote(escaped), bindings)
      end
    end
  else
    quote do
      def unquote(name)(_bindings \\ []), do: unquote(escaped)
    end
  end
end
```

#### Phase 2: Compile-time error handling

Catch tokenizer/parser/compiler errors at compile time with helpful messages that reference the template name and include line numbers.

```elixir
defmacro template(name, source) do
  try do
    json = compile_template(source)
    generate_function(name, json)
  rescue
    e in Tokenizer.Error ->
      reraise CompileError,
              [description: "template #{inspect(name)} has a syntax error: #{Exception.message(e)}", line: e.line],
              __STACKTRACE__

    e in Parser.Error ->
      reraise CompileError,
              [description: "template #{inspect(name)} has a parse error: #{Exception.message(e)}", line: e.line],
              __STACKTRACE__

    e in ArgumentError ->
      reraise CompileError,
              [description: "template #{inspect(name)} failed to compile: #{Exception.message(e)}"],
              __STACKTRACE__
  end
end
```

Error types and their handling:
- **Tokenizer.Error**: Syntax errors like unterminated strings → "has a syntax error"
- **Parser.Error**: Structure errors like unexpected tokens → "has a parse error"
- **ArgumentError**: Compiler errors like unknown elements → "failed to compile"

All errors include line numbers when available, enabling IDE navigation to the source location.

#### Phase 3: Template from file

The `template/2` macro accepts a `file:` option (and optional `format:` override) to load templates from external `.cheex` files (similar to Phoenix's `.eex` files).

```elixir
defmacro template(name, opts) when is_list(opts) do
  format = Keyword.get(opts, :format,
    Module.get_attribute(__CALLER__.module, :juvet_template_format))
  path = Keyword.fetch!(opts, :file)
  # Path is relative to the calling module's file
  caller_dir = Path.dirname(__CALLER__.file)
  full_path = Path.expand(path, caller_dir)

  # Read and compile at compile time
  source = File.read!(full_path)
  compiled = compile_template(source)

  # Register external resource for recompilation
  quote do
    @external_resource unquote(full_path)
    unquote(generate_template_function(name, compiled, format))
  end
end
```

**Usage:**

```elixir
defmodule MyApp.Templates do
  use Juvet.Template

  template :welcome, file: "templates/welcome.cheex"
  template :goodbye, file: "templates/goodbye.cheex"
  template :legacy, file: "templates/legacy.cheex", format: :json
end
```

#### Phase 4: Multiple templates per module

Ensure multiple `template` calls work correctly in a single module. Test various combinations:

```elixir
defmodule MyApp.Templates do
  use Juvet.Template

  template :header_only, ":slack.header{text: \"Hello\"}"
  template :with_divider, """
  :slack.header{text: "Title"}
  :slack.divider
  """
  template :full_message, """
  :slack.header{text: "Welcome <%= name %>"}
  :slack.divider
  :slack.section "Your balance is <%= balance %>"
  """
end
```

#### Phase 5: Development conveniences

- **Recompilation on file changes**: The `@external_resource` attribute in Phase 3 enables Mix to detect when template files change and recompile the module.
- **Better error messages**: Include original template line numbers in error messages by tracking source positions through the pipeline.
- **Template inspection**: Add a way to inspect the compiled JSON for debugging:

```elixir
# Optional: store compiled JSON as module attribute for inspection
def __templates__ do
  %{
    welcome: @welcome_compiled,
    goodbye: @goodbye_compiled
  }
end
```

### Considerations

- Templates with dynamic structure (conditionals, loops in EEx) work naturally since EEx handles them at eval time
- The Juvet template syntax itself is static; dynamism comes from EEx interpolation
- For complex dynamic structures, users can use multiple templates or raw JSON construction

## Views

Views are top-level containers used for Slack surfaces like modals and home tabs. A view wraps blocks with additional metadata fields (`type`, `private_metadata`).

### Syntax

```
:slack.view
  type: :modal
  private_metadata: "some metadata string"
  blocks:
    .header{text: "Hello <%= name %>"}
    .divider
    .section "Welcome"
```

Child elements use `.element` shorthand to inherit the `:slack` platform from the parent `:slack.view`. The full `:slack.header` syntax also works and is equivalent.

### Output

```json
{
  "type": "modal",
  "private_metadata": "some metadata string",
  "blocks": [
    {"type": "header", "text": {"type": "plain_text", "text": "Hello <%= name %>"}},
    {"type": "divider"},
    {"type": "section", "text": {"type": "mrkdwn", "text": "Welcome"}}
  ]
}
```

### Fields

- `type` (required) - The view type as an atom. Converted to string in JSON. Common values: `:modal`, `:home`
- `private_metadata` (optional) - Arbitrary string metadata. Supports EEx interpolation. Only included in output if present.
- `blocks:` (child key) - List of block elements, compiled using standard block compilation.

### AST

The parser produces the following AST for a view template:

```elixir
[%{
  platform: :slack,
  element: :view,
  attributes: %{type: :modal, private_metadata: "some metadata string"},
  children: %{
    blocks: [
      %{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}},
      %{platform: :slack, element: :divider, attributes: %{}},
      %{platform: :slack, element: :section, attributes: %{text: "Welcome"}}
    ]
  }
}]
```

No parser changes are required. The existing parser handles `:slack.view` as a regular element, `type:` and `private_metadata:` as block-style attributes, and `blocks:` as a child key with nested elements.

## Template Partials

Template partials allow reusable block-level fragments to be included inside views. Partials are defined with the `partial/2` macro, which stores AST for inlining into parent templates at compile time. Partials don't compile to standalone JSON or generate callable functions.

### Syntax

```
:slack.partial{template: :template_name}
:slack.partial{template: :template_name, binding1: "value", binding2: "<%= expr %>"}
```

- `template:` (required) - references another template by name
- Other attributes become bindings that substitute into the partial's EEx markers
- Dynamic bindings use EEx interpolation in strings, consistent with other cheex attributes

### Usage

```elixir
defmodule MyTemplates do
  use Juvet.Template

  # Define reusable partial (block-level fragment)
  partial :user_header, ":slack.header{text: \"Hello <%= name %>\"}"

  # Or from a file
  # partial :user_header, file: "templates/user_header.cheex"

  # Use with static binding inside a view
  template :welcome_page, """
  :slack.view
    type: :modal
    blocks:
      :slack.partial{template: :user_header, name: "Alice"}
      :slack.divider
      :slack.section "Welcome to the app"
  """

  # Use with dynamic binding (EEx passthrough)
  template :dashboard, """
  :slack.view
    type: :modal
    blocks:
      :slack.partial{template: :user_header, name: "<%= user_name %>"}
      :slack.divider
      :slack.section "Your dashboard"
  """
end

# Static partial - no bindings needed
MyTemplates.welcome_page()

# Dynamic partial - pass bindings at runtime
MyTemplates.dashboard(user_name: "Bob")
```

### How It Works

Partials are resolved entirely at compile time:

```
Template Source
    |
    v
Tokenizer/Parser: :partial parsed as a regular element
    |
    v
Partial Resolution:
    1. Look up referenced template's stored AST
    2. Substitute bindings into the AST
       (e.g., "<%= name %>" → "<%= user_name %>")
    3. Replace :partial element with inlined blocks
    4. Recursively resolve any nested partials
    |
    v
Compiler: Combined AST compiles to JSON
    |
    v
Runtime: Only EEx evaluation (no JSON parsing/merging)
```

### Nested Partials

Partials can include other partials. Resolution is recursive:

```elixir
partial :greeting, ":slack.header{text: \"Hello <%= name %>\"}"

template :full_page, """
:slack.view
  type: :modal
  blocks:
    :slack.partial{template: :greeting, name: "<%= user %>"}
    :slack.divider
    :slack.section "Page content"
"""
```

When `:full_page` is compiled:
1. Inline `:greeting_card` → finds `:partial` for `:greeting`
2. Inline `:greeting` → no more partials
3. Final AST: header + divider + section
4. Compile to JSON with EEx markers preserved

### Binding Substitution

Bindings map the partial's attributes to EEx markers in the referenced template:

```elixir
# Partial defines: "Hello <%= name %>"
# Parent passes: name: "<%= user_name %>"
# Result: "Hello <%= user_name %>"
```

Static values are substituted directly:

```elixir
# Partial defines: "Hello <%= name %>"
# Parent passes: name: "Alice"
# Result: "Hello Alice"
```

### Ordering Requirement

Partials must be defined before templates that reference them. This is because resolution happens at compile time during macro expansion:

```elixir
# Correct: partial defined first
partial :header, ":slack.header{text: \"<%= title %>\"}"
template :page, """
:slack.view
  type: :modal
  blocks:
    :slack.partial{template: :header, title: "Welcome"}
"""

# Error: partial not yet defined
template :page, """
:slack.view
  type: :modal
  blocks:
    :slack.partial{template: :header, title: "Welcome"}
"""
partial :header, ":slack.header{text: \"<%= title %>\"}"
# => ** (CompileError) partial :header not found (line 4, column 5)
```

### Error Handling

All partial errors include line and column information when available.

**Missing template attribute:**
```
partial is missing required template: attribute (line 1, column 1)
```

**Partial not found:**
```
partial :unknown not found (line 2, column 1)
```

**Circular reference:**
```
circular partial reference detected: a -> b -> a (line 1, column 1)
```

### Introspection

Templates store their AST for partial resolution. You can inspect a template's AST:

```elixir
MyTemplates.__template_ast__(:user_header)
# => [%{platform: :slack, element: :header, attributes: %{text: "Hello <%= name %>"}, ...}]
```

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
