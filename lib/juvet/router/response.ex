defmodule Juvet.Router.Response do
  @moduledoc """
  Represents a single response to a request from a platform.
  """

  @type t :: %__MODULE__{
          body: String.t() | nil,
          status: integer() | String.t()
        }

  defstruct [:status, :body]

  def new(options \\ []) do
    %__MODULE__{
      body: Keyword.get(options, :body, ""),
      status: Keyword.get(options, :status, 200)
    }
  end
end
