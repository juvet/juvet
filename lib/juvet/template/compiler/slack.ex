defmodule Juvet.Template.Compiler.Slack do
  @moduledoc """
  Compiles AST elements for the Slack platform into Block Kit JSON.

  Wraps compiled elements in `{"blocks":[...]}` format.
  Delegates to element-specific modules for compilation.
  """

  alias Juvet.Template.Compiler.Slack.Elements.{Divider, Header}

  def compile([]), do: ~s({"blocks":[]})

  def compile(ast) do
    %{blocks: Enum.map(ast, &compile_element/1)}
    |> Jason.encode!()
  end

  defp compile_element(%{element: :divider} = el), do: Divider.compile(el)
  defp compile_element(%{element: :header} = el), do: Header.compile(el)
end
