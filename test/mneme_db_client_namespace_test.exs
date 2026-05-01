defmodule MnemeDbClientNamespaceTest do
  use ExUnit.Case, async: false

  alias MnemeDbClient.{Application, Collection, Error, Native, Pool}

  setup do
    previous = System.get_env("MNEME_NATIVE_STUB_SUCCESS")
    System.put_env("MNEME_NATIVE_STUB_SUCCESS", "1")

    on_exit(fn ->
      case previous do
        nil -> System.delete_env("MNEME_NATIVE_STUB_SUCCESS")
        value -> System.put_env("MNEME_NATIVE_STUB_SUCCESS", value)
      end
    end)

    :ok
  end

  test "top-level wrappers delegate successfully" do
    assert is_binary(MnemeDbClient.version())
    assert {:ok, 1} = MnemeDbClient.abi_version()
    assert MnemeDbClient.native_available?() == true
    assert %Mneme.Error{} = Error.new(:internal, "ok")
  end

  test "application wrapper starts underlying application" do
    pid =
      case Application.start(:normal, []) do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end

    assert is_pid(pid)
  end

  test "collection and pool wrappers delegate end-to-end" do
    assert {:ok, collection} = Collection.new("docs", dimension: 3)
    assert :ok = Collection.insert(collection, "doc_1", [1.0, 0.0, 0.0])
    assert {:ok, 1} = Collection.count(collection)

    assert {:ok, 1} =
             Collection.insert_many(collection, [{"doc_2", [0.0, 1.0, 0.0], [metadata: "x"]}])

    assert {:ok, _results} = Collection.search(collection, [1.0, 0.0, 0.0], limit: 2)
    assert {:error, %Mneme.Error{code: :native_unavailable}} = Collection.build_hnsw(collection)
    assert :ok = Collection.save(collection, "/tmp/mnemedb_client_roundtrip.mneme")
    assert {:ok, loaded} = Collection.load("/tmp/mnemedb_client_roundtrip.mneme")
    assert :ok = Collection.delete(loaded, "doc_2")
    assert {:ok, 1} = Collection.delete_many(loaded, ["doc_1"])
    assert :ok = Collection.close(loaded)

    assert {:ok, pool} = Pool.start_link(collection: collection)
    assert {:ok, _} = Pool.search(pool, [1.0, 0.0, 0.0], limit: 1)
  end

  test "native wrapper delegates all native boundary functions" do
    assert Native.available?()
    assert {:ok, 1} = Native.abi_version()
    assert {:ok, ref} = Native.collection_new("native", 3, :cosine)

    assert :ok = Native.collection_insert(ref, "doc_1", [1.0, 0.0, 0.0], nil)

    assert {:ok, 1} =
             Native.collection_insert_batch(ref, [{"doc_2", [0.0, 1.0, 0.0], "meta"}])

    assert {:ok, 2} = Native.collection_count(ref)
    assert {:ok, _} = Native.collection_search_flat(ref, [1.0, 0.0, 0.0], 2)

    assert {:error, %Mneme.Error{code: :native_unavailable}} =
             Native.collection_build_hnsw(ref, %{})

    assert {:error, %Mneme.Error{code: :native_unavailable}} =
             Native.collection_search_hnsw(ref, [], 1, nil)

    assert :ok = Native.collection_save(ref, "/tmp/mnemedb_client_native.mneme")

    assert {:ok, loaded_ref, _name, _dimension, _metric} =
             Native.collection_load("/tmp/mnemedb_client_native.mneme")

    assert :ok = Native.collection_delete(loaded_ref, "doc_2")
    assert {:ok, 1} = Native.collection_delete_batch(loaded_ref, ["doc_1"])
    assert :ok = Native.collection_free(loaded_ref)
  end
end
