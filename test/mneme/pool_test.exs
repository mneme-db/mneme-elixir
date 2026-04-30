defmodule Mneme.PoolTest do
  use ExUnit.Case, async: true
  @moduletag :scaffold

  alias Mneme.{Collection, Pool}

  test "pool starts and delegates search" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
    {:ok, pool} = Pool.start_link(collection: collection)

    assert {:error, %Mneme.Error{code: :native_unavailable}} =
             Pool.search(pool, [1.0, 0.0, 0.0], limit: 1)
  end

  test "start_link returns error when collection is missing" do
    previous = Process.flag(:trap_exit, true)

    try do
      assert {:error, {:missing_option, :collection}} = Pool.start_link([])
    after
      Process.flag(:trap_exit, previous)
    end
  end

  test "start_link registers process when name is provided" do
    collection = %Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
    name = :mneme_pool_test_registration

    assert {:ok, pid} = Pool.start_link(collection: collection, name: name)
    assert Process.whereis(name) == pid
  end
end
