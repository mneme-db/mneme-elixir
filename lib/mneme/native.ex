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
  def collection_new(_name, _dimension, _metric) do
    if stub_success?() do
      {:ok, make_ref()}
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
  def collection_insert(_ref, _id, _vector, _metadata),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

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
  def collection_insert_batch(_ref, _entries),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Deletes one id from the native collection.

  ## Examples

      iex> Mneme.Native.collection_delete(make_ref(), "doc_1")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_delete(collection_ref(), String.t()) :: :ok | {:error, Error.t()}
  def collection_delete(_ref, _id),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Deletes many ids from the native collection.

  ## Examples

      iex> Mneme.Native.collection_delete_batch(make_ref(), ["doc_1", "doc_2"])
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_delete_batch(collection_ref(), [String.t()]) ::
          {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_delete_batch(_ref, _ids),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Returns row count for a native collection.

  ## Examples

      iex> Mneme.Native.collection_count(make_ref())
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_count(collection_ref()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_count(_ref), do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Runs flat (exact) search through native code.

  ## Examples

      iex> Mneme.Native.collection_search_flat(make_ref(), [1.0, 0.0, 0.0], 5)
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_search_flat(collection_ref(), [number()], pos_integer()) ::
          {:ok, [Mneme.Result.t()]} | {:error, Error.t()}
  def collection_search_flat(_ref, _query, _limit),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

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
  def collection_save(_ref, _path),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @doc """
  Loads a native collection from disk.

  ## Examples

      iex> Mneme.Native.collection_load("docs.mneme")
      {:error, %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}}
  """
  @spec collection_load(String.t()) :: {:ok, collection_ref()} | {:error, Error.t()}
  def collection_load(_path) do
    if stub_success?() do
      {:ok, make_ref()}
    else
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
    end
  end

  defp stub_success? do
    System.get_env("MNEME_NATIVE_STUB_SUCCESS") == "1"
  end
end
