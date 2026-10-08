# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Changed

- **Breaking:** Juvet calls Slack with Req and encodes JSON with Jason instead of
  HTTPoison and Poison. Both are now configurable, the same way Phoenix and
  Swoosh are: `config :juvet, :json_library, Jason` and
  `config :juvet, :http_client, Juvet.HTTPClient.Req`.
- **Breaking:** `Juvet.SlackAPI` no longer `use`s `HTTPoison.Base`, so
  `SlackAPI.post/3`, `SlackAPI.start/0` and the other HTTPoison functions are
  gone. `make_request/2` returns `{:ok, %{status:, headers:, body:}}`, and
  `parse_response/1` and `render_response/1` take that shape and pass
  `{:error, reason}` through instead of raising.
- **Breaking:** the minimum Elixir version is now 1.15, which Req's HTTP stack
  (Finch, Mint) requires.
- `config :juvet, :json_encoder` is deprecated in favour of `:json_library`. It is
  still read when `:json_library` is not set.
- `Juvet.Plug` decodes JSON bodies with the configured library at runtime.
- Slack OAuth serializes JSON with the configured library. `oauth2` keeps using
  its own Tesla adapter.

### Security

- The Slack OAuth flow now requires a `state` parameter. The request phase
  stores a random state in a signed, HttpOnly cookie scoped to the callback
  endpoint (`Juvet.OAuth.State`), and the callback routes to the `error`
  action with `context.error == :invalid_state` when it doesn't match.
  The cookie is signed with the conn's `secret_key_base` (set by Phoenix
  endpoints), or with `slack: [state_secret: ...]` when it's configured.
  **Breaking:** the request phase returns a configuration error when neither
  is set.
- The Slack authorize URL no longer includes `client_secret`. It was being
  sent to the browser of every user who started OAuth.

### Added

- `Juvet.HTTPClient`, a behaviour for the HTTP client, with `Juvet.HTTPClient.Req`
  as the default. Req options can be set with
  `config :juvet, Juvet.HTTPClient.Req, [...]`.
- `Juvet.JSON`, which encodes and decodes with the configured `:json_library`.
- Cheex attribute values can be dotted paths (`text: item.decision`, any
  depth), desugaring to the equivalent `<%= item.decision %>` binding lookup.
  Segments must be adjacent; richer expressions keep the `<%= expr %>` escape
  hatch.
- Dynamic partial args (bare identifiers, dotted paths, or `<%= expr %>`
  values) now substitute like macro parameters into every expression position
  of the partial body — EEx segments, code blocks, `if` conditions and bodies,
  and `for` collections — instead of only exact leaf `<%= name %>` occurrences
  in attribute strings. Call sites no longer need per-field
  `<% x = item.x %>` extraction blocks before `.partial{...}`. Loop variables
  shadow same-named args; literal args keep the existing leaf substitution
  unchanged.

### Fixed

- `for x <- group.items` (a dotted or complex collection expression) no longer
  raises `KeyError` when the loop has a sibling `<% %>` code block; the
  collection is resolved at runtime like in the code-block-free path.

- Templates can now have a top-level `blocks:` (no `.view` wrapper), which
  compiles to a bare list of blocks — suitable for a Slack **message**
  (`chat.postMessage`) rather than a modal/home view. The generated function
  returns the block list directly. A loose list of top-level elements (without a
  `blocks:` key) is rejected with a clear error.
- `Juvet.SlackAPI` now surfaces rate limiting: a Slack `HTTP 429` response is
  parsed into an `ok: false` body with `error: "ratelimited"` and a
  `retry_after` value (seconds) read from the `Retry-After` header, so callers
  can back off for the duration Slack requests instead of treating it as an
  opaque parse error.
- Cheex templates can now conditionally render a select's or radio button group's
  `initial_option` with `<%= if %>` around the option child. The slot resolves to
  a single object when the condition is true and is omitted entirely when false,
  matching what Slack expects; previously this crashed at template compile time.
  ([#132](https://github.com/juvet/juvet/pull/132))
- Documented the Elixir/OTP version support policy: Juvet supports Elixir ~> 1.14
  on OTP 25+, with CI testing both the supported floor and the latest stable
  Elixir/OTP pair (the latter with `--warnings-as-errors`). Raising the floor is
  treated as a breaking change and will only happen in a new minor version.
