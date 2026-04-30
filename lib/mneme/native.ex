defmodule Mneme.Native do
  @moduledoc """
  Internal boundary module for native calls.

  This initial phase wires the Elixir-facing contract and error mapping while
  native implementation details are integrated.
  """

  use Zig,
    otp_app: :mneme,
    zig_code_path: Path.expand("../../native/mneme_nif.zig", __DIR__)

  alias Mneme.Error

  @type collection_ref :: reference()

  @spec available?() :: boolean()
  def available? do
    case abi_version() do
      {:ok, _version} -> true
      {:error, _error} -> false
    end
  end

  @spec abi_version() :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def abi_version do
    {:ok, native_abi_version()}
  rescue
    UndefinedFunctionError ->
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
  end

  @spec collection_new(String.t(), pos_integer(), :cosine) ::
          {:ok, collection_ref()} | {:error, Error.t()}
  def collection_new(_name, _dimension, _metric) do
    if stub_success?() do
      {:ok, make_ref()}
    else
      {:error, Error.new(:native_unavailable, "NIF is not loaded")}
    end
  end

  @spec collection_free(collection_ref()) :: :ok | {:error, Error.t()}
  def collection_free(_ref), do: :ok

  @spec collection_insert(collection_ref(), String.t(), [number()], nil | binary()) ::
          :ok | {:error, Error.t()}
  def collection_insert(_ref, _id, _vector, _metadata),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_insert_batch(collection_ref(), list({String.t(), [number()], nil | binary()})) ::
          {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_insert_batch(_ref, _entries),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_delete(collection_ref(), String.t()) :: :ok | {:error, Error.t()}
  def collection_delete(_ref, _id),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_delete_batch(collection_ref(), [String.t()]) ::
          {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_delete_batch(_ref, _ids),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_count(collection_ref()) :: {:ok, non_neg_integer()} | {:error, Error.t()}
  def collection_count(_ref), do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_search_flat(collection_ref(), [number()], pos_integer()) ::
          {:ok, [Mneme.Result.t()]} | {:error, Error.t()}
  def collection_search_flat(_ref, _query, _limit),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_build_hnsw(collection_ref(), map()) :: :ok | {:error, Error.t()}
  def collection_build_hnsw(_ref, _config),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_search_hnsw(collection_ref(), [number()], pos_integer(), pos_integer() | nil) ::
          {:ok, [Mneme.Result.t()]} | {:error, Error.t()}
  def collection_search_hnsw(_ref, _query, _limit, _ef_search),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

  @spec collection_save(collection_ref(), String.t()) :: :ok | {:error, Error.t()}
  def collection_save(_ref, _path),
    do: {:error, Error.new(:native_unavailable, "NIF is not loaded")}

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
