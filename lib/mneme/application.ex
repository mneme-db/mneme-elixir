defmodule Mneme.Application do
  @moduledoc """
  OTP application entrypoint for `mneme`.

  The application currently starts an empty supervisor tree and reserves
  supervision structure for future native runtime services and background jobs.
  """
  use Application

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
    children = []
    Supervisor.start_link(children, strategy: :one_for_one, name: Mneme.Supervisor)
  end
end
