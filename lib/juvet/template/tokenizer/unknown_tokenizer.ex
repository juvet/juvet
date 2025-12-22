defmodule Juvet.Template.Tokenizer.UnknownTokenizer do
  @moduledoc false

  def tokenize_line(line, opts \\ [])

  def tokenize_line(line, _opts) when is_binary(line), do: [:text, [text: line]]

  def tokenize_line(line, _opts), do: [line]
end
