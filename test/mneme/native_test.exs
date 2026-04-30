defmodule Mneme.NativeTest do
  use ExUnit.Case, async: true

  test "abi_version is available through embedded core NIF" do
    assert {:ok, 1} = Mneme.abi_version()
  end

  test "available?/0 reflects abi_version status" do
    assert is_boolean(Mneme.native_available?())
    assert Mneme.native_available?() == match?({:ok, _}, Mneme.abi_version())
  end
end
