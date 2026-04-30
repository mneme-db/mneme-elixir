defmodule Mneme.Pool do
  @moduledoc """
  Optional serialized search wrapper.

  In v0.1 this module is intentionally small and non-mandatory. It provides a
  stable shape for future pooling work while already giving callers a named
  process boundary for search operations.

  Note: this module currently serializes requests through a single `GenServer`.
  It does not provide true parallel pooling semantics yet.

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
  Starts the serialized search process.

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
  def start_link(opts) do
    {gen_opts, init_opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, init_opts, gen_opts)
  end

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
    case Keyword.fetch(opts, :collection) do
      {:ok, collection} ->
        {:ok, %{collection: collection}}

      :error ->
        {:stop, {:missing_option, :collection}}
    end
  end

  @impl true
  def handle_call({:search, query, opts}, _from, state) do
    {:reply, Collection.search(state.collection, query, opts), state}
  end
end
