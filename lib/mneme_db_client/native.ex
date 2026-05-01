defmodule MnemeDbClient.Native do
  @moduledoc false
  @type collection_ref :: Mneme.Native.collection_ref()

  defdelegate available?(), to: Mneme.Native
  defdelegate abi_version(), to: Mneme.Native
  defdelegate collection_new(name, dimension, metric), to: Mneme.Native
  defdelegate collection_free(ref), to: Mneme.Native
  defdelegate collection_insert(ref, id, vector, metadata), to: Mneme.Native
  defdelegate collection_insert_batch(ref, entries), to: Mneme.Native
  defdelegate collection_delete(ref, id), to: Mneme.Native
  defdelegate collection_delete_batch(ref, ids), to: Mneme.Native
  defdelegate collection_count(ref), to: Mneme.Native
  defdelegate collection_search_flat(ref, query, limit), to: Mneme.Native
  defdelegate collection_build_hnsw(ref, config), to: Mneme.Native
  defdelegate collection_search_hnsw(ref, query, limit, ef_search), to: Mneme.Native
  defdelegate collection_save(ref, path), to: Mneme.Native
  defdelegate collection_load(path), to: Mneme.Native
end
