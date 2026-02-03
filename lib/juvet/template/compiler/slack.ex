defmodule Juvet.Template.Compiler.Slack do
  @moduledoc """
  Compiles AST elements for the Slack platform into Block Kit JSON.

  Requires a `:slack.view` as the top-level element.
  Delegates to element-specific modules for compilation.
  """

  alias Juvet.Template.Compiler
  alias Juvet.Template.Compiler.Slack.Blocks.{Actions, Context, Divider, Header, Image, Section}
  alias Juvet.Template.Compiler.Slack.Elements.{Button, StaticSelect}
  alias Juvet.Template.Compiler.Slack.Objects.{Option, OptionGroup}
  alias Juvet.Template.Compiler.Slack.View

  @spec compile([Compiler.ast_element()]) :: map()
  def compile([%{element: :view} = view]), do: View.compile(view)

  @doc false
  @spec compile_element(Compiler.ast_element()) :: map()
  def compile_element(%{element: :actions} = el), do: Actions.compile(el)
  def compile_element(%{element: :button} = el), do: Button.compile(el)
  def compile_element(%{element: :static_select} = el), do: StaticSelect.compile(el)
  def compile_element(%{element: :option} = el), do: Option.compile(el)
  def compile_element(%{element: :option_group} = el), do: OptionGroup.compile(el)
  def compile_element(%{element: :context} = el), do: Context.compile(el)
  def compile_element(%{element: :divider} = el), do: Divider.compile(el)
  def compile_element(%{element: :header} = el), do: Header.compile(el)
  def compile_element(%{element: :image} = el), do: Image.compile(el)
  def compile_element(%{element: :section} = el), do: Section.compile(el)

  def compile_element(%{element: element, line: line, column: col}) do
    raise ArgumentError,
          "Unknown Slack element: #{inspect(element)} (line #{line}, column #{col})"
  end

  def compile_element(%{element: element}) do
    raise ArgumentError, "Unknown Slack element: #{inspect(element)}"
  end
end
