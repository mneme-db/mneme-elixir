# Phase 01: Zigler

Zigler enables writing NIF implementations in Zig from Elixir projects.

## Why Zigler is used here

Zigler provides:

- native implementation in `native/mneme_nif.zig`
- tight Elixir module integration (`use Zig`)
- type marshalling support
- tooling for formatting and compilation lifecycle

## Current project usage

`Mneme.Native` is wired with:

```elixir
use Zig,
  otp_app: :mneme,
  zig_code_path: Path.expand("../../native/mneme_nif.zig", __DIR__)
```

This currently exposes ABI bootstrap behavior while full collection operations are being wired.

## Precompiled strategy

`zigler_precompiled` is included to support release artifacts with checksum verification, then local build fallback when no artifact matches the host platform.

## Important implementation detail

Zigler constrains imports to module paths. For Option B (embedded core), upstream `mneme` Zig source must live inside this repository path (vendor/mirror/submodule strategy) rather than importing directly from a sibling path.
