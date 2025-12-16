defmodule Juvet.Template.Tokenizer do
  def tokenize(template) when is_binary(template),
    do:
      template
      |> split_lines()
      |> tokenize()

  def tokenize([]), do: []
  def tokenize([h | t]), do: [tokenize_line(h) | tokenize(t)]

  # TODO: This is not too robust. Expand to handle more cases.
  defp split_lines(template),
    do:
      template
      |> String.split("\n", trim: true)

  defp tokenize_line(":slack.divider"), do: {:slack, :divider, []}
end
