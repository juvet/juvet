defmodule Juvet.Template.Compiler.Slack.Elements.RichTextQuote do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.RichTextElement

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :rich_text_quote, attributes: attrs, children: %{elements: elements}}) do
    %{type: "rich_text_quote", elements: Enum.map(elements, &RichTextElement.compile/1)}
    |> maybe_put(:border, attrs[:border])
  end
end
