defmodule Juvet.Template.Tokenizer.ContinuationTokenizer do
  @moduledoc false

  alias Juvet.Template.Tokenizer

  @at_least_one_space_pattern ~r/^ +$/

  def tokenize_line(line, spacing: spacing) do
    [tokenize_spacing(spacing), Tokenizer.tokenize_line(line)]
  end

  defp tokenize_spacing(""), do: 0

  defp tokenize_spacing(spacing) do
    {head, tail} = String.split_at(spacing, 1)

    cond do
      Regex.match?(@at_least_one_space_pattern, head) -> String.length(head) - 1
      true -> tokenize_spacing(tail)
    end
  end
end
