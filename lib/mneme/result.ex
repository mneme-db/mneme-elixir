defmodule Mneme.Result do
  @moduledoc """
  Search result item returned by vector queries.

  Each result contains the matched row id and a similarity score where larger
  values indicate stronger matches for the configured metric.

  ## Examples

      iex> %Mneme.Result{id: "doc_1", score: 0.98}
      %Mneme.Result{id: "doc_1", score: 0.98}
  """

  @type t :: %__MODULE__{
          id: String.t(),
          score: float()
        }

  defstruct [:id, :score]
end
