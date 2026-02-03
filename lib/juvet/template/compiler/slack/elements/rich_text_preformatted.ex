defmodule Juvet.Template.Compiler.Slack.Elements.RichTextPreformatted do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.RichTextElement

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{
        element: :rich_text_preformatted,
        attributes: attrs,
        children: %{elements: elements}
      }) do
    %{type: "rich_text_preformatted", elements: Enum.map(elements, &RichTextElement.compile/1)}
    |> maybe_put(:border, attrs[:border])
  end
end
