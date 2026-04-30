defmodule Mneme.Collection do
  @moduledoc """
  Primary user-facing API for vector collections.

  `Mneme.Collection` validates Elixir inputs and delegates native work through
  the internal native boundary. This wrapper is intentionally strict so invalid inputs fail
  early with `%Mneme.Error{}` values instead of reaching the native layer.

  A collection tracks four core attributes:

  - `ref`: native collection handle
  - `name`: logical collection name
  - `dimension`: vector width
  - `metric`: similarity metric (`:cosine` in this phase)

  Typical lifecycle:

  1. create or load a collection (`new/2`, `load/2`)
  2. insert or delete rows (`insert/4`, `insert_many/3`, `delete/2`)
  3. query vectors (`search/3`)
  4. optionally build HNSW (`build_hnsw/2`) and persist (`save/2`)
  5. close resources (`close/1`)

  ## Examples

      iex> Mneme.Collection.new("docs")
      {:error, %Mneme.Error{code: :invalid_argument, message: "dimension must be a positive integer"}}

      iex> collection = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.search(collection, [1.0, 0.0, 0.0], limit: 5)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """

  alias Mneme.{Error, Native, Result}

  @enforce_keys [:ref, :name, :dimension, :metric]
  defstruct [:ref, :name, :dimension, :metric]

  @type t :: %__MODULE__{
          ref: reference(),
          name: String.t(),
          dimension: pos_integer(),
          metric: :cosine
        }

  @type entry :: {String.t(), [number()], keyword()}

  @doc """
  Creates a new collection and returns a `%Mneme.Collection{}` descriptor.

  ## Options

  - `:dimension` (required) - positive integer vector dimension.
  - `:metric` (optional) - currently only `:cosine`.

  ## Examples

      iex> Mneme.Collection.new("docs")
      {:error, %Mneme.Error{code: :invalid_argument, message: "dimension must be a positive integer"}}

      iex> Mneme.Collection.new("docs", dimension: 0)
      {:error, %Mneme.Error{code: :invalid_argument, message: "dimension must be a positive integer"}}
  """
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(name, opts \\ []) when is_binary(name) do
    dimension = Keyword.get(opts, :dimension)
    metric = Keyword.get(opts, :metric, :cosine)

    with :ok <- validate_dimension(dimension),
         :ok <- validate_metric(metric),
         {:ok, ref} <- Native.collection_new(name, dimension, metric) do
      {:ok, %__MODULE__{ref: ref, name: name, dimension: dimension, metric: metric}}
    end
  end

  @doc """
  Loads a collection from a persisted `.mneme` file.

  The resulting descriptor can be used with normal collection operations such
  as `count/1`, `search/3`, and `insert/4`.

  ## Examples

      iex> Mneme.Collection.load("docs.mneme")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec load(String.t(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def load(path, _opts \\ []) when is_binary(path) do
    with {:ok, ref, name, dimension, metric} <- Native.collection_load(path) do
      {:ok, %__MODULE__{ref: ref, name: name, dimension: dimension, metric: metric}}
    end
  end

  @doc """
  Persists a collection to a `.mneme` file.

  The resulting file can later be loaded with `load/2`.

  ## Examples

      iex> collection = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.save(collection, "docs.mneme")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec save(t(), String.t()) :: :ok | {:error, Error.t()}
  def save(%__MODULE__{ref: ref}, path) when is_binary(path),
    do: Native.collection_save(ref, path)

  @doc """
  Explicitly closes/frees the native collection resource.

  Closing is optional in short-lived scripts, but recommended for long-running
  processes that create many collections over time.

  ## Examples

      iex> collection = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.close(collection)
      :ok
  """
  @spec close(t()) :: :ok | {:error, Error.t()}
  def close(%__MODULE__{ref: ref}), do: Native.collection_free(ref)

  @doc """
  Inserts a single vector row by id.

  Input validation includes:

  - id is a binary
  - vector length matches collection dimension
  - vector values are numeric

  ## Options

  - `:metadata` - optional binary metadata payload.

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.insert(c, "doc_1", [1.0])
      {:error, %Mneme.Error{code: :dimension_mismatch, message: "vector length does not match collection dimension"}}
  """
  @spec insert(t(), String.t(), [number()], keyword()) :: :ok | {:error, Error.t()}
  def insert(%__MODULE__{} = collection, id, vector, opts \\ [])
      when is_binary(id) and is_list(vector) do
    metadata = Keyword.get(opts, :metadata)

    with :ok <- validate_non_empty_id(id),
         :ok <- validate_metadata(metadata),
         :ok <- validate_vector(vector, collection.dimension) do
      Native.collection_insert(collection.ref, id, normalize_vector(vector), metadata)
    end
  end

  @doc """
  Inserts multiple rows.

  Entries are `{id, vector, opts}` tuples. Each entry is validated with the
  same vector checks used by `insert/4`.

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.insert_many(c, [{"doc_1", [1.0, 0.0, 0.0], []}])
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec insert_many(t(), [entry()], keyword()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def insert_many(%__MODULE__{} = collection, entries, _opts \\ []) when is_list(entries) do
    with :ok <- validate_entries(entries, collection.dimension) do
      normalized =
        Enum.map(entries, fn {id, vector, opts} ->
          {id, normalize_vector(vector), Keyword.get(opts, :metadata)}
        end)

      Native.collection_insert_batch(collection.ref, normalized)
    end
  end

  @doc """
  Deletes a row by id.

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.delete(c, "doc_1")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec delete(t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(%__MODULE__{ref: ref}, id) when is_binary(id), do: Native.collection_delete(ref, id)

  @doc """
  Deletes multiple rows by id.

  Returns the number of rows deleted when supported by the native layer.

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.delete_many(c, ["doc_1", "doc_2"])
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec delete_many(t(), [String.t()]) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def delete_many(%__MODULE__{ref: ref}, ids) when is_list(ids) do
    with :ok <- validate_ids(ids) do
      Native.collection_delete_batch(ref, ids)
    end
  end

  @doc """
  Returns the number of rows in the collection.

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.count(c)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec count(t()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def count(%__MODULE__{ref: ref}), do: Native.collection_count(ref)

  @doc """
  Searches the collection by vector similarity.

  ## Options

  - `:limit` - positive integer result count (default `10`).
  - `:index` - `:flat` or `:hnsw` (default `:flat`).
  - `:ef_search` - optional HNSW search parameter.

  Returns `{:ok, [%Mneme.Result{}, ...]}` on success.

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.search(c, [1.0, 0.0, 0.0], index: :foo)
      {:error, %Mneme.Error{code: :invalid_argument, message: "index must be :flat or :hnsw"}}
  """
  @spec search(t(), [number()], keyword()) :: {:ok, [Result.t()]} | {:error, Error.t()}
  def search(%__MODULE__{} = collection, query, opts \\ []) when is_list(query) do
    limit = Keyword.get(opts, :limit, 10)
    index = Keyword.get(opts, :index, :flat)
    ef_search = Keyword.get(opts, :ef_search)

    with :ok <- validate_positive_integer(limit, :limit),
         :ok <- validate_optional_positive_integer(ef_search, :ef_search),
         :ok <- validate_vector(query, collection.dimension) do
      normalized_query = normalize_vector(query)

      case index do
        :flat -> Native.collection_search_flat(collection.ref, normalized_query, limit)
        :hnsw -> Native.collection_search_hnsw(collection.ref, normalized_query, limit, ef_search)
        _ -> {:error, Error.new(:invalid_argument, "index must be :flat or :hnsw")}
      end
    end
  end

  @doc """
  Builds an HNSW index for the collection.

  This call configures index build parameters and delegates work to the native
  engine. The index can then be queried with `search/3` using `index: :hnsw`.

  ## Options

  - `:m` (default `16`)
  - `:ef_construction` (default `64`)
  - `:ef_search` (default `32`)
  - `:seed` (default `42`)

  ## Examples

      iex> c = %Mneme.Collection{ref: make_ref(), name: "docs", dimension: 3, metric: :cosine}
      iex> Mneme.Collection.build_hnsw(c, m: 0)
      {:error, %Mneme.Error{code: :invalid_argument, message: "m must be a positive integer"}}
  """
  @spec build_hnsw(t(), keyword()) :: :ok | {:error, Error.t()}
  def build_hnsw(%__MODULE__{ref: ref}, opts \\ []) do
    config = %{
      m: Keyword.get(opts, :m, 16),
      ef_construction: Keyword.get(opts, :ef_construction, 64),
      ef_search: Keyword.get(opts, :ef_search, 32),
      seed: Keyword.get(opts, :seed, 42)
    }

    with :ok <- validate_positive_integer(config.m, :m),
         :ok <- validate_positive_integer(config.ef_construction, :ef_construction),
         :ok <- validate_positive_integer(config.ef_search, :ef_search),
         :ok <- validate_non_negative_integer(config.seed, :seed) do
      Native.collection_build_hnsw(ref, config)
    end
  end

  defp validate_entries(entries, dimension) do
    Enum.reduce_while(entries, :ok, fn
      {id, vector, opts}, :ok when is_binary(id) and is_list(vector) and is_list(opts) ->
        metadata = Keyword.get(opts, :metadata)

        case validate_entry(id, vector, metadata, dimension) do
          :ok ->
            {:cont, :ok}

          error ->
            {:halt, error}
        end

      _other, :ok ->
        {:halt,
         {:error, Error.new(:invalid_argument, "entries must be {id, vector, opts} tuples")}}
    end)
  end

  defp validate_metric(:cosine), do: :ok

  defp validate_metric(_),
    do: {:error, Error.new(:invalid_argument, "only :cosine metric is supported")}

  defp validate_dimension(value), do: validate_positive_integer(value, :dimension)

  defp validate_entry(id, vector, metadata, dimension) do
    with :ok <- validate_non_empty_id(id),
         :ok <- validate_metadata(metadata) do
      validate_vector(vector, dimension)
    end
  end

  defp validate_ids(ids) do
    if Enum.all?(ids, &is_binary/1) do
      :ok
    else
      {:error, Error.new(:invalid_argument, "ids must be a list of binaries")}
    end
  end

  defp validate_non_empty_id(""),
    do: {:error, Error.new(:invalid_argument, "id must be a non-empty binary")}

  defp validate_non_empty_id(id) when is_binary(id), do: :ok

  defp validate_metadata(nil), do: :ok
  defp validate_metadata(metadata) when is_binary(metadata), do: :ok

  defp validate_metadata(_metadata),
    do: {:error, Error.new(:invalid_argument, "metadata must be a binary when provided")}

  defp validate_vector(values, dimension) when is_integer(dimension) and dimension > 0 do
    cond do
      length(values) != dimension ->
        {:error,
         Error.new(:dimension_mismatch, "vector length does not match collection dimension")}

      Enum.all?(values, &is_number/1) ->
        :ok

      true ->
        {:error, Error.new(:invalid_argument, "vector entries must be numbers")}
    end
  end

  defp validate_vector(_values, _dimension) do
    {:error, Error.new(:internal, "collection has invalid dimension")}
  end

  defp normalize_vector(values), do: Enum.map(values, &(&1 * 1.0))

  defp validate_positive_integer(value, _field) when is_integer(value) and value > 0, do: :ok

  defp validate_positive_integer(_value, field) do
    {:error, Error.new(:invalid_argument, "#{field} must be a positive integer")}
  end

  defp validate_optional_positive_integer(nil, _field), do: :ok

  defp validate_optional_positive_integer(value, field),
    do: validate_positive_integer(value, field)

  defp validate_non_negative_integer(value, _field) when is_integer(value) and value >= 0, do: :ok

  defp validate_non_negative_integer(_value, field) do
    {:error, Error.new(:invalid_argument, "#{field} must be a non-negative integer")}
  end
end
