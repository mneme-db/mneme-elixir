defmodule Mneme.ErrorTest do
  use ExUnit.Case, async: true

  test "new/2 builds error for known code" do
    assert %Mneme.Error{code: :invalid_argument, message: "bad"} =
             Mneme.Error.new(:invalid_argument, "bad")
  end

  test "new/2 raises for unknown code" do
    assert_raise ArgumentError, ~r/invalid Mneme\.Error code/, fn ->
      Mneme.Error.new(:bogus, "bad")
    end
  end
end
