defmodule MnemeDbClient.Pool do
  @moduledoc """
  Pool API under the `MnemeDbClient` namespace.
  """
  @type t :: Mneme.Pool.t()

  defdelegate start_link(opts), to: Mneme.Pool
  defdelegate search(pool, query, opts \\ []), to: Mneme.Pool
end
