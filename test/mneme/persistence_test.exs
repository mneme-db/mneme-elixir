defmodule Mneme.PersistenceTest do
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

  test "save/load round trip preserves count and search results" do
    path =
      Path.join(System.tmp_dir!(), "mneme_roundtrip_#{System.unique_integer([:positive])}.mneme")

    assert {:ok, collection} = Collection.new("docs", dimension: 3)
    assert :ok = Collection.insert(collection, "doc_1", [1.0, 0.0, 0.0])
    assert :ok = Collection.insert(collection, "doc_2", [0.5, 0.5, 0.0])
    assert :ok = Collection.save(collection, path)

    assert {:ok, loaded} = Collection.load(path)
    assert {:ok, 2} = Collection.count(loaded)

    assert {:ok, original_results} = Collection.search(collection, [1.0, 0.0, 0.0], limit: 2)
    assert {:ok, loaded_results} = Collection.search(loaded, [1.0, 0.0, 0.0], limit: 2)
    assert loaded_results == original_results
  end
end
