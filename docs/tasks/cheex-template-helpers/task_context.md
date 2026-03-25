# Task Context: Template Helpers Option

## Problem Statement
Template modules need a way to automatically make helper module functions available as bindings in templates, without manually passing them each time.

## Architecture Patterns

### Current `__using__/1` (template.ex:72-82)
- Accepts `format:` option, stores as `@juvet_template_format` module attribute
- Imports `template/2`, `template/3`, `partial/2` macros
- Registers `@juvet_templates` (accumulate) and `@juvet_template_asts` attributes

### Current Function Generation (template.ex:604-664)
- `generate_json_function/2` and `generate_map_function/2` each have 3 code paths:
  1. For-loop/code-block path: `compiled_to_quoted` with bindings var
  2. EEx path: `eval_map` or `EEx.eval_string` with bindings
  3. Static path: literal map/json, ignores bindings
- All paths receive `bindings` as a keyword list parameter
- Helper captures need to be merged into bindings BEFORE any evaluation

### Approach (from user spec)
1. `__using__/1`: Accept `:helpers` option, store as `@juvet_template_helpers` module attribute
2. `generate_*_function`: At compile time, iterate helper modules' public functions, generate captures, prepend to bindings via `Keyword.merge(helpers, bindings)` so user bindings take precedence
3. Conflict handling: Require unique function names across helpers, raise at compile time on conflicts

## Dependencies

### Key File
- `lib/juvet/template.ex` — `__using__/1` (line 72), `generate_json_function` (line 604), `generate_map_function` (line 635)

### Test Files
- `test/juvet/template_test.exs` — e2e template tests

## Impact Summary
- Files impacted: 1 (`template.ex`) + tests
- Pattern match: Clear (extends existing `__using__` option pattern)
- Components crossed: 1 (template layer only)
- Data model changes: New module attribute `@juvet_template_helpers`
- Integration points: Internal only
