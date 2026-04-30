defmodule Mneme.CollectionOperationsTest do
  use ExUnit.Case, async: false

  alias Mneme.Collection

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

  test "insert_many, count, delete, delete_many, and close operate on stub-backed collection" do
    assert {:ok, collection} = Collection.new("ops", dimension: 3)

    assert {:ok, 3} =
             Collection.insert_many(collection, [
               {"doc_1", [1.0, 0.0, 0.0], [metadata: "a"]},
               {"doc_2", [0.0, 1.0, 0.0], []},
               {"doc_3", [0.0, 0.0, 1.0], []}
             ])

    assert {:ok, 3} = Collection.count(collection)

    assert :ok = Collection.delete(collection, "doc_2")
    assert {:ok, 2} = Collection.count(collection)

    assert {:ok, 1} = Collection.delete_many(collection, ["doc_1"])
    assert {:ok, 1} = Collection.count(collection)

    assert :ok = Collection.close(collection)
  end

  test "new, insert, count, and search succeed in stub-success mode" do
    assert {:ok, collection} = Collection.new("happy", dimension: 3)
    assert {:ok, 0} = Collection.count(collection)

    assert :ok = Collection.insert(collection, "doc_a", [1.0, 0.0, 0.0])
    assert {:ok, 1} = Collection.count(collection)

    assert {:ok, [%Mneme.Result{id: "doc_a"} | _]} =
             Collection.search(collection, [1.0, 0.0, 0.0], limit: 1)
  end
end
