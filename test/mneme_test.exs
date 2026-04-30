defmodule MnemeTest do
  use ExUnit.Case, async: true

  doctest Mneme
  doctest Mneme.Application
  doctest Mneme.Collection
  doctest Mneme.Error
  doctest Mneme.Pool
  doctest Mneme.Result

  test "version/0 works" do
    assert is_binary(Mneme.version())
    assert Mneme.version() != ""
  end

  test "native_available?/0 works" do
    assert Mneme.native_available?()
  end
end
