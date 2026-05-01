defmodule MnemeDbClient do
  @moduledoc """
  Public entrypoint for the `mnemedb_client` Elixir client.
  """

  alias MnemeDbClient.Native

  @spec version() :: String.t()
  def version do
    case Application.spec(:mnemedb_client, :vsn) do
      nil -> "0.0.0"
      vsn -> List.to_string(vsn)
    end
  end

  @spec abi_version() :: {:ok, non_neg_integer()} | {:error, MnemeDbClient.Error.t()}
  def abi_version, do: Native.abi_version()

  @spec native_available?() :: boolean()
  def native_available?, do: Native.available?()
end
