# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added

- Documented the Elixir/OTP version support policy: Juvet supports Elixir ~> 1.14
  on OTP 25+, with CI testing both the supported floor and the latest stable
  Elixir/OTP pair (the latter with `--warnings-as-errors`). Raising the floor is
  treated as a breaking change and will only happen in a new minor version.
