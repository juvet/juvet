defmodule Juvet.Template.ParserError do
  @moduledoc """
  Exception raised for errors encountered during parsing of Templates.

  Includes line and column information for error reporting.
  """

  defexception [:message, :line, :column]

  @type t :: %__MODULE__{
          message: String.t(),
          line: pos_integer() | nil,
          column: pos_integer() | nil
        }

  @impl true
  def message(%{message: message, line: nil}), do: message
  def message(%{message: message, line: line, column: nil}), do: "#{message} (line #{line})"

  def message(%{message: message, line: line, column: col}),
    do: "#{message} (line #{line}, column #{col})"
end
