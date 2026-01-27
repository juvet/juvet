defmodule Juvet.Template.Compiler.Slack.Blocks.Context do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :context} = el) do
    %{type: "context", elements: compile_elements(el)}
  end

  defp compile_elements(%{children: %{elements: elements}}) when is_list(elements) do
    Enum.map(elements, &compile_context_element/1)
  end

  defp compile_elements(_el), do: []

  # Images in context are rendered as image objects (not blocks)
  defp compile_context_element(%{element: :image, attributes: attrs}) do
    %{type: "image"}
    |> maybe_put(:image_url, attrs[:url])
    |> maybe_put(:alt_text, attrs[:alt_text])
  end

  # Text elements are rendered as text objects
  defp compile_context_element(%{element: :text, attributes: attrs}) do
    Slack.Objects.Text.compile(attrs[:text], attrs)
  end

  # Fall back to standard element compilation for other types
  defp compile_context_element(el) do
    Slack.compile_element(el)
  end
end
