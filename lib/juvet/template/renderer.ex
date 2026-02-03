defmodule Juvet.Template.Renderer do
  @moduledoc false

  alias Juvet.Template.{Compiler, Parser, Tokenizer}

  require EEx

  def eval(source, []), do: source
  def eval(source, bindings) when is_binary(source), do: EEx.eval_string(source, bindings)
  def eval(source, bindings) when is_map(source), do: Juvet.Template.eval_map(source, bindings)

  def precompile(template),
    do:
      template
      |> Tokenizer.tokenize()
      |> Parser.parse()
      |> Compiler.compile()

  def render(template, bindings \\ []),
    do:
      template
      |> precompile()
      |> eval(bindings)
end
