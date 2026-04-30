# Changelog

## 0.1.0

- Initial Elixir-facing API scaffold for `mneme`.
- Added public wrapper modules (`Mneme`, `Mneme.Collection`, `Mneme.Error`, `Mneme.Result`, `Mneme.Pool`).
- Added native boundary module (`Mneme.Native`) and Zigler bootstrap wiring.
- Added `Mneme.abi_version/0` path through NIF bootstrap.
- Chosen NIF strategy direction documented as Option B (embed core into NIF) with Option A fallback.
- Added design docs, learning docs, examples, and CI baseline.
