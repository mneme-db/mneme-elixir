defmodule Mneme.Error do
  @moduledoc """
  Normalized error type for all `mneme` operations.
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

  @spec new(code(), String.t()) :: t()
  def new(code, message) when code in @valid_codes and is_binary(message),
    do: %__MODULE__{code: code, message: message}

  def new(code, _message) do
    raise ArgumentError,
          "invalid Mneme.Error code #{inspect(code)}; expected one of #{inspect(@valid_codes)}"
  end
end
