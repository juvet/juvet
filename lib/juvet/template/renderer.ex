defmodule Juvet.Template.Renderer do
  @moduledoc false

  alias Juvet.Template.{Compiler, Parser, Tokenizer}

  require EEx

  def eval(source, []), do: source
  def eval(source, bindings), do: EEx.eval_string(source, bindings)

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
