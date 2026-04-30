defmodule Mneme.HnswTest do
  use ExUnit.Case, async: true
  @moduletag :scaffold

  alias Mneme.Collection

  test "build_hnsw validates positive options" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.build_hnsw(collection, m: 0)
  end

  test "build_hnsw validates non-negative seed" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}

    assert {:error, %Mneme.Error{code: :invalid_argument}} =
             Collection.build_hnsw(collection, seed: -1)
  end
end
