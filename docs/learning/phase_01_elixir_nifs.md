# Phase 01: Elixir NIF Basics

Native Implemented Functions (NIFs) let Elixir call native code (C/Zig/Rust/etc.) with very low overhead. In this project, Zig is used through Zigler to expose `mneme` engine capabilities to Elixir.

## Why NIFs are powerful and risky

NIFs run inside the same VM process as BEAM schedulers.

Benefits:

- extremely low call overhead
- no serialization boundary like a Port
- direct data marshalling support

Risks:

- memory safety bugs can crash the VM
- long-running native calls can starve schedulers
- native resource leaks do not behave like normal BEAM garbage leaks

## Scheduler safety: dirty vs normal

Use normal schedulers only for quick native operations.

Use dirty schedulers for expensive operations:

- large inserts/searches
- index construction
- disk-heavy save/load paths

This prevents VM responsiveness regressions in real workloads.

## Resource model

Native handles (such as a collection pointer) should be wrapped as NIF resources.
Users should never manage raw pointers. The boundary module owns lifecycle and maps failures to `%Mneme.Error{}`.

## Practical guidance for this project

- Keep normal-scheduler NIF functions short.
- Use dirty schedulers for CPU-heavy or IO-heavy work.
- Represent native state with NIF resources, not user-visible pointers.
- Preserve idiomatic Elixir return contracts: `{:ok, value}` or `{:error, %Mneme.Error{}}`.
