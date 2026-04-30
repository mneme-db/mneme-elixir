# Architecture

`mneme-elixir` is split into:

- `Mneme.Collection`: user-facing API with argument validation
- `Mneme.Native`: internal NIF boundary
- `Mneme.Error` and `Mneme.Result`: stable public data contracts
- `Mneme.Pool`: optional concurrency wrapper, not mandatory for core usage

The architecture keeps native concerns isolated and keeps Elixir API semantics explicit (`{:ok, value}` or `{:error, %Mneme.Error{}}`).

## Boundary policy

- Applications should call `Mneme` and `Mneme.Collection` only.
- `Mneme.Native` is considered internal and may change without compatibility guarantees.
- Mapping from native statuses to `%Mneme.Error{}` happens at the boundary to prevent C/Zig leakage into user-facing API shapes.

## Runtime notes

- The NIF bootstrap is active for ABI inspection.
- Full collection handle/resource wiring is in progress.
- Expensive native operations are planned for dirty scheduler execution once implemented.
