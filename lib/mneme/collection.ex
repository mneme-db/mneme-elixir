defmodule Mneme.Collection do
  @moduledoc """
  Idiomatic collection API over the native `mneme` engine.
  """

  alias Mneme.{Error, Native, Result}

  @enforce_keys [:ref, :name, :dimension, :metric]
  defstruct [:ref, :name, :dimension, :metric]

  @type t :: %__MODULE__{
          ref: Native.collection_ref(),
          name: String.t(),
          dimension: pos_integer(),
          metric: :cosine
        }

  @type entry :: {String.t(), [number()], keyword()}

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

  @spec load(String.t(), keyword()) :: {:ok, t()} | {:error, Error.t()}
  def load(path, _opts \\ []) when is_binary(path) do
    with {:ok, ref} <- Native.collection_load(path) do
      {:ok, %__MODULE__{ref: ref, name: Path.basename(path), dimension: 0, metric: :cosine}}
    end
  end

  @spec save(t(), String.t()) :: :ok | {:error, Error.t()}
  def save(%__MODULE__{ref: ref}, path) when is_binary(path),
    do: Native.collection_save(ref, path)

  @spec close(t()) :: :ok | {:error, Error.t()}
  def close(%__MODULE__{ref: ref}), do: Native.collection_free(ref)

  @spec insert(t(), String.t(), [number()], keyword()) :: :ok | {:error, Error.t()}
  def insert(%__MODULE__{} = collection, id, vector, opts \\ [])
      when is_binary(id) and is_list(vector) do
    metadata = Keyword.get(opts, :metadata)

    with :ok <- validate_vector(vector, collection.dimension) do
      Native.collection_insert(collection.ref, id, vector, metadata)
    end
  end

  @spec insert_many(t(), [entry()], keyword()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def insert_many(%__MODULE__{} = collection, entries, _opts \\ []) when is_list(entries) do
    with :ok <- validate_entries(entries, collection.dimension) do
      normalized =
        Enum.map(entries, fn {id, vector, opts} ->
          {id, vector, Keyword.get(opts, :metadata)}
        end)

      Native.collection_insert_batch(collection.ref, normalized)
    end
  end

  @spec delete(t(), String.t()) :: :ok | {:error, Error.t()}
  def delete(%__MODULE__{ref: ref}, id) when is_binary(id), do: Native.collection_delete(ref, id)

  @spec delete_many(t(), [String.t()]) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def delete_many(%__MODULE__{ref: ref}, ids) when is_list(ids),
    do: Native.collection_delete_batch(ref, ids)

  @spec count(t()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def count(%__MODULE__{ref: ref}), do: Native.collection_count(ref)

  @spec search(t(), [number()], keyword()) :: {:ok, [Result.t()]} | {:error, Error.t()}
  def search(%__MODULE__{} = collection, query, opts \\ []) when is_list(query) do
    limit = Keyword.get(opts, :limit, 10)
    index = Keyword.get(opts, :index, :flat)
    ef_search = Keyword.get(opts, :ef_search)

    with :ok <- validate_positive_integer(limit, :limit),
         :ok <- validate_vector(query, collection.dimension) do
      case index do
        :flat -> Native.collection_search_flat(collection.ref, query, limit)
        :hnsw -> Native.collection_search_hnsw(collection.ref, query, limit, ef_search)
        _ -> {:error, Error.new(:invalid_argument, "index must be :flat or :hnsw")}
      end
    end
  end

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
         :ok <- validate_positive_integer(config.ef_search, :ef_search) do
      Native.collection_build_hnsw(ref, config)
    end
  end

  defp validate_entries(entries, dimension) do
    Enum.reduce_while(entries, :ok, fn
      {id, vector, opts}, :ok when is_binary(id) and is_list(vector) and is_list(opts) ->
        case validate_vector(vector, dimension) do
          :ok -> {:cont, :ok}
          error -> {:halt, error}
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

  defp validate_positive_integer(value, _field) when is_integer(value) and value > 0, do: :ok

  defp validate_positive_integer(_value, field) do
    {:error, Error.new(:invalid_argument, "#{field} must be a positive integer")}
  end
end
