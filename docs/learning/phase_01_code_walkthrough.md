# Phase 01: Code Walkthrough

- `Mneme` exposes package and native capability checks.
- `Mneme.Collection` defines the idiomatic public API and validates options/vectors.
- `Mneme.Native` defines low-level function contracts and has a Zigler ABI bootstrap (`abi_version`) active.
- `Mneme.Error` normalizes native and wrapper errors.
- `Mneme.Result` models search outputs.
- `Mneme.Pool` provides an optional serialized search wrapper.

## Current execution paths

- `Mneme.abi_version/0` calls into Zig NIF code.
- Most collection operations intentionally return `:native_unavailable` while resource-backed implementations are completed.

## Next implementation step

Implement `native/mneme_nif.zig` + `Mneme.Native` collection operations by embedding/syncing `mneme` core sources inside this repository (Option B), while preserving Option A as fallback when embedding is not viable for a specific target.

## Precompiled NIF setup status

- dependency wiring exists (`zigler_precompiled`)
- target matrix and checksum flow documented
- CI/release artifact automation is the next packaging milestone
