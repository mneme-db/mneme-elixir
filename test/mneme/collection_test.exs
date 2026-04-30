defmodule Mneme.CollectionTest do
  use ExUnit.Case, async: true

  alias Mneme.Collection

  test "new validates dimension" do
    assert {:error, %Mneme.Error{code: :invalid_argument}} = Collection.new("docs", dimension: 0)
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
end
