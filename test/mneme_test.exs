defmodule MnemeTest do
  use ExUnit.Case, async: true

  doctest Mneme
  doctest Mneme.Application
  doctest Mneme.Collection
  doctest Mneme.Error
  doctest Mneme.Native
  doctest Mneme.Pool
  doctest Mneme.Result

  test "version/0 works" do
    assert Mneme.version() == "0.1.0"
  end

  test "native_available?/0 works" do
    assert Mneme.native_available?()
  end
end
