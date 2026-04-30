# Phase 01: Resource Management

`Mneme.Collection` wraps a native handle reference.

Goals:

- rely on GC-safe resource finalization
- avoid exposing manual pointer operations to users
- provide optional explicit `close/1` for deterministic cleanup

NimblePool remains optional and is not required for core API usage in v0.1.

## Resource lifecycle principles

1. Create collection/resource in the native boundary.
2. Hand back opaque Elixir-facing handle/state.
3. Use defensive validation before native calls.
4. Free resources automatically when references are dropped, with optional explicit close.

## NimblePool tradeoffs in this project

When it helps:

- cap expensive concurrent searches/builds
- control backpressure under bursty workloads

When it does not:

- wrapping each collection in a process without measurable gains
- replacing native resource semantics with process ownership semantics

Current direction is to keep pooling optional while the native layer stabilizes.
