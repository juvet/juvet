defmodule Juvet.Template.Compiler.Slack.Elements.RichTextList do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :rich_text_list, attributes: attrs, children: %{elements: elements}}) do
    %{
      type: "rich_text_list",
      style: attrs.style,
      elements: Enum.map(elements, &Slack.compile_element/1)
    }
    |> maybe_put(:indent, attrs[:indent])
    |> maybe_put(:offset, attrs[:offset])
    |> maybe_put(:border, attrs[:border])
  end
end
