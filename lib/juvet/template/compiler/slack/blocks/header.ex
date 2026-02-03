defmodule Juvet.Template.Compiler.Slack.Blocks.Header do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :header, attributes: %{text: %{text: _} = text_attrs}}) do
    %{
      type: "header",
      text: Text.compile(text_attrs.text, Map.put_new(text_attrs, :type, :plain_text))
    }
  end

  def compile(%{element: :header, attributes: %{text: text} = attrs}) do
    %{type: "header", text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))}
  end
end
