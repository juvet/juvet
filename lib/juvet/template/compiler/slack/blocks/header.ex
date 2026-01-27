defmodule Juvet.Template.Compiler.Slack.Blocks.Header do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :header, attributes: %{text: text} = attrs}) do
    %{type: "header", text: Text.plain_text(text, attrs)}
  end
end
