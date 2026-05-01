defmodule MnemeDbClient.Collection do
  @moduledoc """
  Collection API under the `MnemeDbClient` namespace.
  """
  @type t :: Mneme.Collection.t()
  @type entry :: Mneme.Collection.entry()

  defdelegate new(name, opts \\ []), to: Mneme.Collection
  defdelegate load(path, opts \\ []), to: Mneme.Collection
  defdelegate save(collection, path), to: Mneme.Collection
  defdelegate close(collection), to: Mneme.Collection
  defdelegate insert(collection, id, vector, opts \\ []), to: Mneme.Collection
  defdelegate insert_many(collection, entries, opts \\ []), to: Mneme.Collection
  defdelegate delete(collection, id), to: Mneme.Collection
  defdelegate delete_many(collection, ids), to: Mneme.Collection
  defdelegate count(collection), to: Mneme.Collection
  defdelegate search(collection, query, opts \\ []), to: Mneme.Collection
  defdelegate build_hnsw(collection, opts \\ []), to: Mneme.Collection
end
