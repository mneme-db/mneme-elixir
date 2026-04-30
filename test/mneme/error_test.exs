defmodule Mneme.ErrorTest do
  use ExUnit.Case, async: true

  @all_codes [
    :invalid_argument,
    :out_of_memory,
    :dimension_mismatch,
    :io,
    :index_not_built,
    :index_stale,
    :internal,
    :native_unavailable
  ]

  test "new/2 builds error for known code" do
    assert %Mneme.Error{code: :invalid_argument, message: "bad"} =
             Mneme.Error.new(:invalid_argument, "bad")
  end

  test "new/2 returns an exception struct" do
    assert Exception.exception?(Mneme.Error.new(:internal, "x"))
  end

  test "all documented codes can be constructed" do
    for code <- @all_codes do
      assert %Mneme.Error{code: ^code, message: "ok"} = Mneme.Error.new(code, "ok")
    end
  end

  test "new/2 raises for unknown code" do
    assert_raise ArgumentError, ~r/invalid Mneme\.Error code/, fn ->
      Mneme.Error.new(:bogus, "bad")
    end
  end
end
