defmodule Mneme.CollectionTest do
  use ExUnit.Case, async: true
  @moduletag :scaffold

  alias Mneme.Collection

  test "new validates dimension" do
    assert {:error, %Mneme.Error{code: :invalid_argument}} = Collection.new("docs", dimension: 0)
  end

  test "new validates non-integer dimension and unsupported metric" do
    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.new("docs", dimension: 1.0)

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.new("docs", dimension: 3, metric: :euclidean)
  end

  test "new/1 returns validation error instead of arity crash" do
    assert {:error, %Mneme.Error{code: :invalid_argument}} = Collection.new("docs")
  end

  test "insert validates vector dimension before native call" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :dimension_mismatch}} =
             Collection.insert(collection, "id", [1.0])
  end

  test "search validates index option" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.search(collection, [1.0, 0.0, 0.0], index: :foo)
  end

  test "search validates limit and ef_search" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.search(collection, [1.0, 0.0, 0.0], limit: 0)

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.search(collection, [1.0, 0.0, 0.0], ef_search: 0)
  end

  test "search with invalid collection dimension returns structured error" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 0, metric: :cosine}

    assert {:error, %Mneme.Error{code: :internal, message: "collection has invalid dimension"}} =
             Collection.search(collection, [1.0, 0.0, 0.0])
  end

  test "insert validates vector entries, metadata, and non-empty id" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.insert(collection, "id", [1, 2, "x"])

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.insert(collection, "id", [1.0, 2.0, 3.0], metadata: 123)

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.insert(collection, "", [1.0, 2.0, 3.0])
  end

  test "insert_many and delete_many validate ids" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.insert_many(collection, [{"", [1.0, 0.0, 0.0], []}])

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.delete_many(collection, ["ok", 123])
  end
end
