defmodule Juvet.Template.Compiler.SlackCompiler do
  @moduledoc """
  Compiles AST elements for the Slack platform into Block Kit JSON.

  Wraps compiled elements in `{"blocks":[...]}` format.
  """

  def compile([]), do: ~s({"blocks":[]})

  def compile(ast) do
    blocks = Enum.map_join(ast, ",", &compile_element/1)
    ~s({"blocks":[#{blocks}]})
  end

  def compile_element(%{element: :divider}), do: ~s({"type":"divider"})
end
