# TARGET SHAPE EXAMPLE:
# This script demonstrates intended HNSW workflow once native support is active.
{:ok, collection} = Mneme.Collection.new("docs", dimension: 3)
:ok = Mneme.Collection.build_hnsw(collection, m: 16, ef_construction: 128, ef_search: 64, seed: 42)
{:ok, _results} = Mneme.Collection.search(collection, [1.0, 0.0, 0.0], limit: 10, index: :hnsw, ef_search: 64)
