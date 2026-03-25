# Implementation Plan: EEx Code Block Support in Cheex Templates

## Overview

Add support for `<% ... %>` code blocks in Cheex templates so that variables defined in code blocks are available to subsequent expressions (`<%= %>` and `#{}`) within the same scope level. Currently code blocks are silently skipped by the parser. The implementation extends the existing for-loop pattern (AST nodes → compiled markers → quoted AST generation) to thread bindings through element sequences containing code blocks.

## Desired End State

Templates like this work:

```
:slack.view
  type: :modal
  blocks:
    <% recording = Tatsu.Recordings.current_recording(decision) %>
    .section{text: "Started: #{recording.started_at}", type: :mrkdwn}
    <% duration = calculate_duration(recording) %>
    .section{text: "Duration: #{duration}", type: :mrkdwn}
```

Code blocks:
- Execute sequentially at runtime
- Define variables available to subsequent sibling elements at the same level
- Work inside for-loop bodies (per-iteration scope)
- Produce no output in the data structure (filtered out)
- Provide clear error messages with source line/column on failure

## Out of Scope

- Code blocks affecting parent or ancestor scope (only siblings at same level)
- Compile-time evaluation of code blocks (all runtime via `Code.eval_string`)
- Code block support in partial `substitute_bindings` (partials with code blocks use the runtime evaluation path)
- Multi-line code blocks spanning multiple `<% %>` tags (each tag is independent)

## Technical Approach

### Layer 1: Parser — Create `:code_block` AST Nodes

**Current state**: `parser.ex:72` skips all `:eex_code` tokens except `"end"`.

**Change**: Instead of skipping, create AST nodes for non-`end` code tokens.

Three locations need the same change:
1. **Top level** (`do_parse`, line 72) — Currently: `do_parse([{:eex_code, _, _} | rest], acc, platform), do: do_parse(rest, acc, platform)`. Change to: match `"end"` specifically to skip, create `:code_block` node for everything else.
2. **Nested elements** (`nested_elements`, line 291) — Same pattern.
3. **For-loop bodies** (`parse_for_body`, line 381+) — Already handles `"end"` specially. Add clause for other `:eex_code` tokens before the existing skip clauses.

AST node structure (mirrors for-loop pattern):
```elixir
%{
  node_type: :code_block,
  code: "recording = get_recording(decision)",
  line: 4,
  column: 5
}
```

Also update `resolve_partials` (line ~268) and `validate_platform!` (line ~772) to pass through `:code_block` nodes (same as they do for `:for_loop` nodes).

### Layer 2: Compiler — Mark with `__code_block__`

**Current state**: `compiler/slack.ex:69-76` handles `:for_loop` nodes.

**Change**: Add a `compile_element` clause for `:code_block` nodes:

```elixir
def compile_element(%{node_type: :code_block} = node) do
  %{__code_block__: true, code: node.code, line: node.line, column: node.column}
end
```

This follows the exact same pattern as the `__for__: true` marker.

### Layer 3: Template — Detection and Code Generation

This is the core of the implementation. Three sub-changes:

#### 3a. Detection function

Add `map_contains_code_block?/1` (mirrors `map_contains_for?/1` at line 810-819):

```elixir
defp map_contains_code_block?(%{__code_block__: true}), do: true
defp map_contains_code_block?(map) when is_map(map),
  do: Enum.any?(map, fn {_k, v} -> map_contains_code_block?(v) end)
defp map_contains_code_block?(list) when is_list(list),
  do: Enum.any?(list, &map_contains_code_block?/1)
defp map_contains_code_block?(_), do: false
```

#### 3b. Function generation routing

Modify `generate_map_function` (line 618) and `generate_json_function` (line 587) to route to the quoted AST path when code blocks are present:

```elixir
map_contains_for?(compiled) or map_contains_code_block?(compiled) ->
  # quoted AST path (existing for-loop path)
```

This is a single condition change in each function.

#### 3c. Quoted AST generation for lists with code blocks

This is the most complex change. The current `compiled_to_quoted` for lists (line 696-709) handles for-loops by chunking. Code blocks need a different strategy: **binding threading via `Enum.map_reduce`**.

When a list contains `__code_block__` markers, generate code that:
1. Threads bindings through the list sequentially using `Enum.map_reduce`
2. Code blocks execute via `Code.eval_string(code, bindings)` → `{nil, updated_bindings}`
3. Regular elements evaluate via `eval_map(element, current_bindings)` → `{result, same_bindings}`
4. For-loop elements evaluate with current bindings
5. Filter out `nil` values (from code blocks) from the final list

The key insight: `Code.eval_string/2` returns `{result, new_binding}` where `new_binding` is a keyword list containing all variables defined in the evaluated code. This is exactly what we need to thread forward.

When a list contains BOTH code blocks and for-loops, the `Enum.map_reduce` approach handles both: code blocks update bindings, for-loops evaluate with current bindings, regular elements eval_map with current bindings.

#### 3d. `compiled_to_quoted` clause for code block maps

Add a clause that matches `%{__code_block__: true}` and generates the `Code.eval_string` call. This clause is used within the `map_reduce` callback.

### Error Handling

Wrap `Code.eval_string` calls with error context:
- Catch exceptions and re-raise with template source line/column from the `__code_block__` marker
- This gives users actionable error messages like "Error in code block at line 4: undefined function get_recording/1"

## Critical Files for Implementation

- `lib/juvet/template/parser.ex` — Lines 72, 291, 381+ (skip → create nodes), ~268 (resolve_partials), ~772 (validate_platform!)
- `lib/juvet/template/compiler/slack.ex` — After line 76 (new compile_element clause)
- `lib/juvet/template.ex` — Lines 587/618 (routing), 696-709 (list quoted AST), after 819 (detection)
- `test/juvet/template/parser_test.exs` — Parser tests (pattern: lines 515-584 for-loop tests)
- `test/juvet/template_test.exs` — E2E tests (pattern: lines 33-72 binding tests)
- `test/juvet/template/compiler/slack_test.exs` — Compiler tests
