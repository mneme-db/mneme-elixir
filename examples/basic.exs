# TARGET SHAPE EXAMPLE:
# This script demonstrates intended usage.
# It succeeds end-to-end only when the native backend is available.
{:ok, collection} = Mneme.Collection.new("docs", dimension: 3)
:ok = Mneme.Collection.insert(collection, "doc_1", [1.0, 0.0, 0.0], metadata: "source=example")
{:ok, _results} = Mneme.Collection.search(collection, [1.0, 0.0, 0.0], limit: 3)
