defmodule Mneme.Pool do
  @moduledoc """
  Optional process wrapper for controlled query execution.

  In v0.1 this module is intentionally small and non-mandatory. It provides a
  stable shape for future pooling work while already giving callers a named
  process boundary for search operations.

  ## Examples

      iex> collection = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> {:ok, pool} = Mneme.Pool.start_link(collection: collection)
      iex> Mneme.Pool.search(pool, [1.0, 0.0, 0.0], limit: 1)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """

  use GenServer

  alias Mneme.Collection

  @type t :: pid()

  @doc """
  Starts the optional pool process.

  Required options:

  - `:collection` - a `%Mneme.Collection{}`

  Optional options:

  - `:name` - process registration name passed to `GenServer.start_link/3`

  ## Examples

      iex> collection = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> {:ok, pid} = Mneme.Pool.start_link(collection: collection)
      iex> is_pid(pid)
      true
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name))

  @doc """
  Executes a search through the pool process.

  This delegates to `Mneme.Collection.search/3` inside the server process.

  ## Examples

      iex> collection = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> {:ok, pool} = Mneme.Pool.start_link(collection: collection)
      iex> Mneme.Pool.search(pool, [1.0, 0.0, 0.0], limit: 1)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec search(t(), [number()], keyword()) ::
          {:ok, [Mneme.Result.t()]} | {:error, Mneme.Error.t()}
  def search(pool, query, opts \\ []), do: GenServer.call(pool, {:search, query, opts})

  @impl true
  def init(opts) do
    {:ok, %{collection: Keyword.fetch!(opts, :collection)}}
  end

  @impl true
  def handle_call({:search, query, opts}, _from, state) do
    {:reply, Collection.search(state.collection, query, opts), state}
  end
end
