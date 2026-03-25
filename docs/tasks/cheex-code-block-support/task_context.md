# Task Context: EEx Code Block Support in Cheex Templates

## Problem Statement
`<% ... %>` code blocks in Cheex templates are silently skipped by the parser (parser.ex:72). Variables defined in code blocks (e.g., `<% recording = func(arg) %>`) need to be available to subsequent expressions (`<%= recording.started_at %>` or `#{recording.started_at}`). This is needed for computing intermediate values in templates.

## Architecture Patterns

### Current Pipeline
1. **Tokenizer** (`tokenizer.ex:550-562`) — Already produces `:eex_code` tokens for `<% ... %>`. No changes needed.
2. **Parser** (`parser.ex:72`) — Silently skips all `:eex_code` tokens at top level. Line 291 skips them in nested elements. Only `<% end %>` is recognized in for-loop bodies (line 381).
3. **Compiler** (`compiler/slack.ex:69-76`) — For-loop pattern: `node_type: :for_loop` → `%{__for__: true, ...}` marker.
4. **Template** (`template.ex:616-645`) — Three code paths: static, dynamic EEx (`eval_map`), for-loop (`compiled_to_quoted`).
5. **Runtime** (`template.ex:464-480`) — `eval_map/2` evaluates each string independently via `EEx.eval_string`. Code block variables can't cross these boundaries.

### For-Loop Reference Implementation
The for-loop feature (commit 5359d02) provides the blueprint:
1. Parser creates `%{node_type: :for_loop}` AST nodes
2. Compiler marks with `%{__for__: true}`
3. `map_contains_for?/1` detects markers in compiled maps
4. `compiled_to_quoted/2` generates quoted Elixir AST with real `for` comprehensions
5. Loop variable added to bindings via `Keyword.put` for `eval_map` calls

### Partial Handling
- `substitute_bindings/2` does compile-time string replacement: `<%= name %>` → binding value
- Only handles simple variable names, not dot-access like `recording.started_at`
- Partials with code blocks would need the same runtime evaluation path as regular templates

## Dependencies

### Key Files (modification candidates)
- `lib/juvet/template/parser.ex` — Lines 72, 291, 381+ (skip clauses → create AST nodes)
- `lib/juvet/template/compiler/slack.ex` — After line 76 (add compile_element clause)
- `lib/juvet/template.ex` — Lines 587/618 (detection), 647-733 (compiled_to_quoted), after 819 (map_contains_code_block?)

### Test Files
- `test/juvet/template/parser_test.exs`
- `test/juvet/template/compiler/slack_test.exs`
- `test/juvet/template_test.exs`

## Implementation Approaches

### Option A: Quoted AST with Binding Threading (Recommended)
Extend the for-loop's `compiled_to_quoted` approach. When a list of elements contains code blocks, generate `Enum.map_reduce` that threads bindings through the sequence. Code blocks execute via `Code.eval_string(code, bindings)` and return updated bindings.

- **Scope**: 3 files (parser, compiler/slack, template) + tests
- **Approach**: Parser creates `:code_block` AST nodes → compiler marks with `__code_block__: true` → `compiled_to_quoted` generates binding-threading code for lists containing code blocks
- **Trade-offs**: Follows existing for-loop pattern closely. Code blocks only affect subsequent siblings at same level (matches EEx scoping). Moderate complexity in `compiled_to_quoted`.

### Option B: Single EEx String Evaluation
Convert the entire template to a single EEx string at compile time and evaluate once with `EEx.eval_string` at runtime. Variables naturally share scope.

- **Scope**: 1-2 files (template.ex primarily)
- **Approach**: When code blocks detected, generate one big EEx string from the compiled map and evaluate it as a whole
- **Trade-offs**: Much simpler. But loses compile-time map generation benefits, everything becomes runtime evaluation, defeats Cheex's design philosophy.

### Option C: Wrapper EEx Template
Wrap the compiled map in an EEx template that runs code blocks first, captures variables, then passes them as bindings to `eval_map`.

- **Scope**: 1-2 files (template.ex)
- **Approach**: Generate a wrapper EEx template: `<% recording = func() %><%= Juvet.Template.eval_map(compiled_map, binding() ++ [recording: recording]) %>`
- **Trade-offs**: Simpler than Option A. But code blocks must all appear before elements (can't interleave), and `binding()` has limitations.

## Impact Summary
- Files impacted: 3-4 (parser, compiler/slack, template, tests)
- Pattern match: Adapts existing for-loop pattern (Medium)
- Components crossed: 3 (parser, compiler, template)
- Data model changes: New AST node type `:code_block`, new compiled marker `__code_block__`
- Integration points: Internal only
- Hard stops: None

## Key Design Decisions Needed
1. **Scope of code block effects** — Only subsequent siblings at same level? (Recommended: yes, matches EEx)
2. **Code block output** — Code blocks produce no output in data structure (filtered as nil)
3. **Interaction with for-loops** — Code blocks inside for-loop bodies should work (per-iteration scope)
4. **Error handling** — Preserve line/column for runtime errors in code blocks
