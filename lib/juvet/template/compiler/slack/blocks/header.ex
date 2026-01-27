defmodule Juvet.Template.Compiler.Slack.Blocks.Header do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :header, attributes: %{text: text} = attrs}) do
    %{type: "header", text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))}
  end
end
