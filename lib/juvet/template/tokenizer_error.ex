defmodule Juvet.Template.TokenizerError do
  @moduledoc """
  Exception raised for errors encountered during tokenization of Templates.
  """

  defexception message: "Tokenizer error occurred"

  @type t :: %__MODULE__{
          message: String.t()
        }
end
