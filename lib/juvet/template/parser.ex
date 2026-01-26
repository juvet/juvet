defmodule Juvet.Template.Parser do
  @moduledoc false

  alias Juvet.Template.Parser.SlackParser

  def parse([]), do: []

  def parse(tokens), do: tokens |> Enum.map(&parse_token/1)

  def parse_token({:slack, token, attrs}), do: SlackParser.parse_token({token, attrs})

  # This is not correct
  def parse_token(token) do
    # token |> IO.inspect(label: "Unparsed token")
    token
  end
end
