defmodule Mneme.Error do
  @moduledoc """
  Normalized error type for all `mneme` operations.

  Library APIs return this struct in `{:error, %Mneme.Error{}}` tuples so
  callers can pattern-match by `:code` while preserving user-readable context
  in `:message`.

  ## Examples

      iex> Mneme.Error.new(:invalid_argument, "bad input")
      %Mneme.Error{code: :invalid_argument, message: "bad input"}
  """

  defexception [:code, :message]

  @type code ::
          :invalid_argument
          | :out_of_memory
          | :dimension_mismatch
          | :io
          | :index_not_built
          | :index_stale
          | :internal
          | :native_unavailable

  @type t :: %__MODULE__{code: code(), message: String.t()}

  @valid_codes [
    :invalid_argument,
    :out_of_memory,
    :dimension_mismatch,
    :io,
    :index_not_built,
    :index_stale,
    :internal,
    :native_unavailable
  ]

  @doc """
  Builds a `%Mneme.Error{}` for a known error code.

  Raises `ArgumentError` if an unknown code is provided.

  ## Examples

      iex> Mneme.Error.new(:native_unavailable, "NIF is not loaded")
      %Mneme.Error{code: :native_unavailable, message: "NIF is not loaded"}

      iex> Mneme.Error.new(:bogus, "bad")
      ** (ArgumentError) invalid Mneme.Error code :bogus; expected one of [:invalid_argument, :out_of_memory, :dimension_mismatch, :io, :index_not_built, :index_stale, :internal, :native_unavailable]
  """
  @spec new(code(), String.t()) :: t()
  def new(code, message) when code in @valid_codes and is_binary(message),
    do: %__MODULE__{code: code, message: message}

  def new(code, _message) do
    raise ArgumentError,
          "invalid Mneme.Error code #{inspect(code)}; expected one of #{inspect(@valid_codes)}"
  end
end
