defmodule Juvet.Template.Compiler.Slack.Elements.RichTextSection do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.RichTextElement

  def compile(%{element: :rich_text_section, children: %{elements: elements}}) do
    %{type: "rich_text_section", elements: Enum.map(elements, &RichTextElement.compile/1)}
  end
end
