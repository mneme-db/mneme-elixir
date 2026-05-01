defmodule MnemeDbClient.Error do
  @moduledoc """
  Error helpers for `MnemeDbClient`.
  """
  @type t :: Mneme.Error.t()
  @type code :: Mneme.Error.code()

  defdelegate new(code, message), to: Mneme.Error
end
