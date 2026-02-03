defmodule Juvet.Template.Compiler.Slack.Blocks.Context do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack
  alias Juvet.Template.Compiler.Slack.Elements.Image, as: ImageElement
  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :context} = el) do
    %{type: "context", elements: compile_elements(el)}
  end

  defp compile_elements(%{children: %{elements: elements}}) when is_list(elements) do
    Enum.map(elements, &compile_context_element/1)
  end

  defp compile_elements(_el), do: []

  # Images in context are rendered as image elements
  defp compile_context_element(%{element: :image} = el) do
    ImageElement.compile(el)
  end

  # Text elements are rendered as text objects
  defp compile_context_element(%{element: :text, attributes: attrs}) do
    Text.compile(attrs[:text], attrs)
  end

  # Fall back to standard element compilation for other types
  defp compile_context_element(el) do
    Slack.compile_element(el)
  end
end
