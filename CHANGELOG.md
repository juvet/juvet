# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

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
