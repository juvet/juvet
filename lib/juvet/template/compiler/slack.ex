defmodule Juvet.Template.Compiler.Slack do
  @moduledoc """
  Compiles AST elements for the Slack platform into Block Kit JSON.

  Wraps compiled elements in `{"blocks":[...]}` format.
  Delegates to element-specific modules for compilation.
  """

  alias Juvet.Template.Compiler.Slack.Elements.Divider

  def compile([]), do: ~s({"blocks":[]})

  def compile(ast) do
    blocks = Enum.map_join(ast, ",", &compile_element/1)
    ~s({"blocks":[#{blocks}]})
  end

  defp compile_element(%{element: :divider} = el), do: Divider.compile(el)
end
