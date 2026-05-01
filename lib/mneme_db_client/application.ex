defmodule MnemeDbClient.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    Mneme.Application.start(:normal, [])
  end
end
