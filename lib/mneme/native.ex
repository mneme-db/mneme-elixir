defmodule Mneme.Native do
  @moduledoc """
  Internal boundary module for native calls.

  This module is considered internal. Application code should use
  `Mneme` and `Mneme.Collection` instead of calling these functions directly.

  Responsibilities:

  - expose a stable Elixir-facing contract for native operations
  - convert NIF availability failures into `%Mneme.Error{}`
  - keep high-level validation logic out of the NIF boundary

  ## Examples

      iex> case Mneme.Native.abi_version() do
      ...>   {:ok, _} -> true
      ...>   {:error, %Mneme.Error{}} -> true
      ...> end
      true

      iex> is_boolean(Mneme.Native.available?())
      true
  """

  use Zig,
    otp_app: :mneme,
    zig_code_path: Path.expand("../../native/mneme_nif.zig", __DIR__)

  alias Mneme.Error

  @type collection_ref :: reference()
  @stub_table :mneme_native_stub_collections
  @stub_saved_table :mneme_native_stub_saved

  @doc """
  Returns true when the native ABI endpoint is callable.

  This function is intentionally conservative: any native initialization
  failure is interpreted as unavailable.

  ## Examples

      iex> is_boolean(Mneme.Native.available?())
      true
  """
  @spec available?() :: boolean()
  def available? do
    case abi_version() do
      {:ok, _version} -> true
      {:error, _error} -> false
    end
  end

  @doc """
  Returns the native ABI version.

  Used by startup checks and diagnostics to confirm compatibility between the
  Elixir wrapper and the native implementation.

  ## Examples

      iex> case Mneme.Native.abi_version() do
      ...>   {:ok, _} -> true
      ...>   {:error, %Mneme.Error{}} -> true
      ...> end
      true
  """
  @spec abi_version() :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def abi_version do
    {:ok, native_abi_version()}
  rescue
    UndefinedFunctionError ->
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
  end

  @doc """
  Creates a native collection handle.

  This is a low-level call. Prefer `Mneme.Collection.new/2` in application code.

  ## Examples

      iex> Mneme.Native.collection_new("docs", 3, :cosine)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_new(String.t(), pos_integer(), :cosine) ::
          {:ok, collection_ref()} | {:error, Error.t()}
  def collection_new(name, dimension, metric) do
    if stub_success?() do
      ref = make_ref()
      put_stub_collection(ref, %{name: name, dimension: dimension, metric: metric, rows: %{}})
      {:ok, ref}
    else
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
    end
  end

  @doc """
  Frees a native collection handle.

  This is idempotent in the current stub implementation.

  ## Examples

      iex> Mneme.Native.collection_free(make_ref())
      :ok
  """
  @spec collection_free(collection_ref()) :: :ok | {:error, Error.t()}
  def collection_free(_ref), do: :ok

  @doc """
  Inserts one vector in the native collection.

  Assumes caller already validated vector length and metadata shape.

  ## Examples

      iex> Mneme.Native.collection_insert(make_ref(), "doc_1", [1.0, 0.0, 0.0], nil)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_insert(collection_ref(), String.t(), [number()], nil | binary()) ::
          :ok | {:error, Error.t()}
  def collection_insert(ref, id, vector, metadata) do
    update_stub_collection(ref, fn state ->
      rows = Map.put(state.rows, id, %{vector: vector, metadata: metadata})
      %{state | rows: rows}
    end)
  end

  @doc """
  Inserts many vectors in one native call.

  Intended for batch throughput when inserting many records.

  ## Examples

      iex> entries = [{"doc_1", [1.0, 0.0, 0.0], nil}]
      iex> Mneme.Native.collection_insert_batch(make_ref(), entries)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_insert_batch(collection_ref(), list({String.t(), [number()], nil | binary()})) ::
          {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_insert_batch(ref, entries) do
    with :ok <-
           update_stub_collection(ref, fn state ->
             %{state | rows: Map.merge(state.rows, build_stub_additions(entries))}
           end) do
      {:ok, length(entries)}
    end
  end

  @doc """
  Deletes one id from the native collection.

  ## Examples

      iex> Mneme.Native.collection_delete(make_ref(), "doc_1")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_delete(collection_ref(), String.t()) :: :ok | {:error, Error.t()}
  def collection_delete(ref, id) do
    update_stub_collection(ref, fn state ->
      %{state | rows: Map.delete(state.rows, id)}
    end)
  end

  @doc """
  Deletes many ids from the native collection.

  ## Examples

      iex> Mneme.Native.collection_delete_batch(make_ref(), ["doc_1", "doc_2"])
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_delete_batch(collection_ref(), [String.t()]) ::
          {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_delete_batch(ref, ids) do
    with :ok <-
           update_stub_collection(ref, fn state ->
             rows = Map.drop(state.rows, ids)
             %{state | rows: rows}
           end) do
      {:ok, length(ids)}
    end
  end

  @doc """
  Returns row count for a native collection.

  ## Examples

      iex> Mneme.Native.collection_count(make_ref())
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_count(collection_ref()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_count(ref) do
    with {:ok, state} <- fetch_stub_collection(ref) do
      {:ok, map_size(state.rows)}
    end
  end

  @doc """
  Runs flat (exact) search through native code.

  ## Examples

      iex> Mneme.Native.collection_search_flat(make_ref(), [1.0, 0.0, 0.0], 5)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_search_flat(collection_ref(), [number()], pos_integer()) ::
          {:ok, [Mneme.Result.t()]} | {:error, Error.t()}
  def collection_search_flat(ref, query, limit) do
    with {:ok, state} <- fetch_stub_collection(ref) do
      results =
        state.rows
        |> Enum.map(fn {id, row} ->
          %{id: id, score: cosine_similarity(query, row.vector)}
        end)
        |> Enum.sort_by(& &1.score, :desc)
        |> Enum.take(limit)
        |> Enum.map(&struct(Mneme.Result, &1))

      {:ok, results}
    end
  end

  @doc """
  Builds HNSW index in native code.

  ## Examples

      iex> Mneme.Native.collection_build_hnsw(make_ref(), %{m: 16, ef_construction: 64, ef_search: 32, seed: 42})
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_build_hnsw(collection_ref(), map()) :: :ok | {:error, Error.t()}
  def collection_build_hnsw(_ref, _config),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Runs HNSW search through native code.

  ## Examples

      iex> Mneme.Native.collection_search_hnsw(make_ref(), [1.0, 0.0, 0.0], 5, 32)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_search_hnsw(collection_ref(), [number()], pos_integer(), pos_integer() | nil) ::
          {:ok, [Mneme.Result.t()]} | {:error, Error.t()}
  def collection_search_hnsw(_ref, _query, _limit, _ef_search),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Saves a native collection to disk.

  ## Examples

      iex> Mneme.Native.collection_save(make_ref(), "docs.mneme")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_save(collection_ref(), String.t()) :: :ok | {:error, Error.t()}
  def collection_save(ref, path) do
    with {:ok, state} <- fetch_stub_collection(ref) do
      ensure_stub_tables!()
      true = :ets.insert(@stub_saved_table, {path, state})
      :ok
    end
  end

  @doc """
  Loads a native collection from disk.

  ## Examples

      iex> Mneme.Native.collection_load("docs.mneme")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_load(String.t()) ::
          {:ok, collection_ref(), String.t(), pos_integer(), :cosine} | {:error, Error.t()}
  def collection_load(path) do
    with {:ok, saved} <- fetch_saved_stub(path) do
      ref = make_ref()
      put_stub_collection(ref, saved)
      {:ok, ref, saved.name, saved.dimension, saved.metric}
    end
  end

  defp stub_success? do
    System.get_env("MNEME_NATIVE_STUB_SUCCESS") == "1"
  end

  defp ensure_stub_tables! do
    if :ets.whereis(@stub_table) == :undefined do
      :ets.new(@stub_table, [:named_table, :public, :set])
    end

    if :ets.whereis(@stub_saved_table) == :undefined do
      :ets.new(@stub_saved_table, [:named_table, :public, :set])
    end
  end

  defp put_stub_collection(ref, state) do
    ensure_stub_tables!()
    true = :ets.insert(@stub_table, {ref, state})
    :ok
  end

  defp fetch_stub_collection(ref) do
    if stub_success?() do
      ensure_stub_tables!()

      case :ets.lookup(@stub_table, ref) do
        [{^ref, state}] ->
          {:ok, state}

        [] ->
          {:error, Error.new(:native_unavailable, "NIF is not loaded")}
      end
    else
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
    end
  end

  defp fetch_saved_stub(path) do
    if stub_success?() do
      ensure_stub_tables!()

      case :ets.lookup(@stub_saved_table, path) do
        [{^path, state}] ->
          {:ok, state}

        [] ->
          {:error, Error.new(:io, "no persisted collection found at path")}
      end
    else
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
    end
  end

  defp update_stub_collection(ref, updater) do
    with {:ok, state} <- fetch_stub_collection(ref) do
      put_stub_collection(ref, updater.(state))
    end
  end

  defp build_stub_additions(entries) do
    Enum.into(entries, %{}, fn {id, vector, metadata} ->
      {id, %{vector: vector, metadata: metadata}}
    end)
  end

  defp cosine_similarity(left, right) do
    {dot, l2_left, l2_right} =
      Enum.zip(left, right)
      |> Enum.reduce({0.0, 0.0, 0.0}, fn {l, r}, {d, ll, rr} ->
        lf = l * 1.0
        rf = r * 1.0
        {d + lf * rf, ll + lf * lf, rr + rf * rf}
      end)

    if l2_left == 0.0 or l2_right == 0.0 do
      0.0
    else
      dot / (:math.sqrt(l2_left) * :math.sqrt(l2_right))
    end
  end
end
