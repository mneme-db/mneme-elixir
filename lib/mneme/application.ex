defmodule Mneme.Application do
  @moduledoc """
  OTP application entrypoint for `mneme`.

  The application currently starts an empty supervisor tree and reserves
  supervision structure for future native runtime services and background jobs.
  """
  use Application
  require Logger

  @doc """
  Starts the `mneme` supervision tree.

  This callback is invoked by OTP when the application starts.

  ## Examples

      iex> case Mneme.Application.start(:normal, []) do
      ...>   {:ok, _} -> true
      ...>   {:error, {:already_started, _}} -> true
      ...> end
      true
  """
  @impl true
  def start(_type, _args) do
    log_native_health()

    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: Mneme.Supervisor)
  end

  defp log_native_health do
    case Mneme.abi_version() do
      {:ok, abi} ->
        Logger.info("mneme native ABI available (abi_version=#{abi})")

      {:error, %Mneme.Error{code: code, message: message}} ->
        Logger.warning("mneme native ABI unavailable (code=#{code}): #{message}")
    end
  end
end
