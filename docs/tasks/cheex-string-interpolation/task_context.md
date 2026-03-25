# Task Context: String Interpolation for Cheex Templates

## Problem Statement
Cheex template string variables need to support string interpolation. Currently, dynamic values in strings require EEx syntax (`<%= name %>`), but a more natural Elixir-like `#{variable}` syntax would be more ergonomic.

## Architecture Patterns

### Current String Handling Pipeline
1. **Tokenizer** (`lib/juvet/template/tokenizer.ex:591-613`) - Quoted strings collected as single `:text` tokens, EEx markers preserved inside
2. **Parser** (`lib/juvet/template/parser.ex:328-335`) - Text tokens become attribute values, EEx expressions wrapped as `"<%= expr %>"`
3. **Compiler** - Strings pass through unchanged to platform-specific output maps
4. **Runtime** (`lib/juvet/template.ex:464-480`) - `eval_map/2` walks structure, calls `EEx.eval_string/2` on strings containing `<%`

### For-Loop Reference Implementation (commit 5359d02)
Pattern for adding new template features:
1. Tokenizer: Recognize syntax → produce tokens
2. Parser: Build AST node
3. Compiler: Mark with metadata
4. Template: Generate code at compile-time

## Dependencies

### Key Files (modification candidates)
- `lib/juvet/template/tokenizer.ex` - `take_quoted_text/3` (lines 591-613)
- `lib/juvet/template/parser.ex` - `value/1` (lines 328-335)
- `lib/juvet/template.ex` - `eval_map/2` (lines 464-480)

### Test Files
- `test/juvet/template/tokenizer_test.exs`
- `test/juvet/template/parser_test.exs`
- `test/juvet/template_test.exs`

## Implementation Approaches

### Option A: Tokenizer-Level Transformation (Recommended)
Transform `#{expr}` to `<%= expr %>` during tokenization in `take_quoted_text/3`.
- Scope: 1 file change (tokenizer.ex) + tests
- Minimal changes, leverages existing EEx evaluation pipeline

### Option B: Parser-Level String Interpolation
Parse `#{expr}` in the parser to create structured interpolation nodes.
- Scope: 2-3 file changes
- More explicit AST, but more complex for no real benefit

### Option C: Full Compile-Time Interpolation
Resolve interpolations at compile-time using Elixir code generation.
- Scope: 4+ file changes
- Best performance but significantly more complex

## Impact Summary
- Files impacted: 1-4 depending on approach
- Pattern match: Clear existing pattern
- Components crossed: 1-2
- Data model changes: None
- Integration points: Internal only
