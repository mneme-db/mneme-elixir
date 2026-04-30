# Mneme

Idiomatic Elixir client for the [`mneme` core engine](https://github.com/mneme-db/mneme), an embedded-first vector and memory database written in Zig.

## Status

This repository provides the Elixir package structure, API contracts, validation layer, and a Zigler NIF bootstrap.

Current native state:

- `Mneme.abi_version/0` is wired through Zigler and returns the embedded ABI version.
- Most collection operations are still scaffolded and currently return `{:error, %Mneme.Error{code: :native_unavailable}}` until full native resource wiring is completed.

## Installation

```elixir
def deps do
  [
    {:mneme, "~> 0.1.0"}
  ]
end
```

## Basic API (Target Shape)

```elixir
{:ok, collection} = Mneme.Collection.new("docs", dimension: 3)
:ok = Mneme.Collection.insert(collection, "doc_1", [1.0, 0.0, 0.0], metadata: "source=chat")
{:ok, results} = Mneme.Collection.search(collection, [1.0, 0.0, 0.0], limit: 10)
```

The snippets above show the intended public API shape. Full end-to-end behavior is completed as native operations are wired.

## HNSW Example (Target Shape)

```elixir
{:ok, collection} = Mneme.Collection.new("docs", dimension: 3)
:ok = Mneme.Collection.build_hnsw(collection, m: 16, ef_construction: 128, ef_search: 64, seed: 42)
{:ok, results} = Mneme.Collection.search(collection, [1.0, 0.0, 0.0], limit: 10, index: :hnsw, ef_search: 64)
```

## Persistence Example (Target Shape)

```elixir
{:ok, collection} = Mneme.Collection.new("docs", dimension: 3)
:ok = Mneme.Collection.save(collection, "docs.mneme")
{:ok, loaded} = Mneme.Collection.load("docs.mneme")
```

## NIF and Precompiled NIF Notes

- Runtime NIFs are built with Zigler.
- Precompiled NIF distribution is planned through `zigler_precompiled`.
- Design details and release workflow are documented in `docs/design/precompiled_nifs.md`.
- Current strategy preference is Option B (embed core into the NIF) with Option A fallback.

## Design docs

- `docs/design/architecture.md`
- `docs/design/nif_strategy.md`
- `docs/design/resource_management.md`
- `docs/design/precompiled_nifs.md`

## Current Limitations

- Collection-native operations are scaffolded and not fully wired yet.
- Metadata filtering is not implemented.
- HNSW persistence behavior follows upstream core constraints (HNSW graph is derived).
- No Windows precompiled artifacts yet.
- Nx tensor input is not required in v0.1.
- `Mneme.Pool` is currently minimal and optional.

## Roadmap

- Complete native resource-backed collection operations (`new`, `insert`, `search`, `save`, `load`).
- Expand ANN/HNSW behavior coverage and error mapping.
- Finalize precompiled NIF pipeline and checksum publishing.
- Evaluate optional Nx tensor support in a non-breaking way.
- Revisit process/pool ergonomics after native performance profiling.

