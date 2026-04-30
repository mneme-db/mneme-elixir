defmodule Mneme do
  @moduledoc """
  Public entrypoint for the `mneme` Elixir client.

  `Mneme` provides package-level introspection and availability checks.
  Day-to-day vector operations live in `Mneme.Collection`.

  Use this module to:

  - read package version information with `version/0`
  - read the native ABI contract version with `abi_version/0`
  - probe whether native operations are currently available with
    `native_available?/0`

  ## Examples

      iex> is_binary(Mneme.version())
      true

      iex> case Mneme.abi_version() do
      ...>   {:ok, _} -> true
      ...>   {:error, %Mneme.Error{}} -> true
      ...> end
      true

      iex> is_boolean(Mneme.native_available?())
      true
  """

  alias Mneme.Native

  @doc """
  Returns the Elixir package version published by this library.

  This value tracks `Mix.Project.config()[:version]` and reflects the Hex
  package release, not the native ABI version.

  ## Examples

      iex> Mneme.version()
      "0.1.0"
  """
  @spec version() :: String.t()
  def version, do: "0.1.0"

  @doc """
  Returns the native ABI version used by the loaded NIF.

  The ABI version is separate from the package version and is used to validate
  compatibility at the native boundary.

  ## Examples

      iex> case Mneme.abi_version() do
      ...>   {:ok, _version} -> true
      ...>   {:error, %Mneme.Error{}} -> true
      ...> end
      true
  """
  @spec abi_version() :: {:ok, non_neg_integer()} | {:error, Mneme.Error.t()}
  def abi_version, do: Native.abi_version()

  @doc """
  Indicates whether the native layer is currently callable.

  This check is useful for startup diagnostics and for building graceful
  fallbacks in environments where the NIF may not be available.

  ## Examples

      iex> is_boolean(Mneme.native_available?())
      true
  """
  @spec native_available?() :: boolean()
  def native_available?, do: Native.available?()
end
