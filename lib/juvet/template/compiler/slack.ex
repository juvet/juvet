defmodule Juvet.Template.Compiler.Slack do
  @moduledoc """
  Compiles AST elements for the Slack platform into Block Kit JSON.

  Wraps compiled elements in `{"blocks":[...]}` format.
  Delegates to element-specific modules for compilation.
  """

  alias Juvet.Template.Compiler.Encoder
  alias Juvet.Template.Compiler.Slack.Blocks.{Actions, Divider, Header, Image, Section}
  alias Juvet.Template.Compiler.Slack.Elements.Button

  def compile([]), do: Encoder.encode!(%{blocks: []})

  def compile(ast) do
    %{blocks: Enum.map(ast, &compile_element/1)}
    |> Encoder.encode!()
  end

  @doc false
  def compile_element(%{element: :actions} = el), do: Actions.compile(el)
  def compile_element(%{element: :button} = el), do: Button.compile(el)
  def compile_element(%{element: :divider} = el), do: Divider.compile(el)
  def compile_element(%{element: :header} = el), do: Header.compile(el)
  def compile_element(%{element: :image} = el), do: Image.compile(el)
  def compile_element(%{element: :section} = el), do: Section.compile(el)
end
