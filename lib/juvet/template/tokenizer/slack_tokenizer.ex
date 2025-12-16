defmodule Juvet.Template.Tokenizer.SlackTokenizer do
  @moduledoc false

  def tokenize_line("divider"), do: [:divider, []]

  def tokenize_line(slack_line) when is_binary(slack_line) do
    slack_line
    |> String.trim()
    |> tokenize_line()
    |> IO.inspect(label: "SlackTokenizer.tokenize_line")
  end
end
