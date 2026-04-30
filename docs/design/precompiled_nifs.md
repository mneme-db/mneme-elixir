# Precompiled NIFs

`zigler_precompiled` is configured as a dependency so the library can ship prebuilt native artifacts once the NIF implementation is stable.

## Intended module wiring

Native modules are declared using Zigler in Elixir modules, for example:

```elixir
use Zig,
  otp_app: :mneme,
  zig_code_path: Path.expand("../../native/mneme_nif.zig", __DIR__)
```

Precompiled artifacts are intended to be downloaded and validated first, with local compilation as fallback.

## Planned release process

1. Build NIF artifacts in CI for supported targets.
2. Publish checksums with each release.
3. Prefer downloading verified artifacts.
4. Fall back to local Zig compilation when no matching artifact exists.

Initial target set:

- macOS arm64
- macOS x86_64
- Linux x86_64

Later targets:

- Linux aarch64
- Windows

## Fallback behavior

- If a matching precompiled artifact exists and checksum verification passes, it is used.
- If no artifact exists for the target, local Zig compilation is attempted.
- If both fail, the native module reports unavailability through `%Mneme.Error{code: :native_unavailable}`.
