defmodule Juvet.Template.Compiler.Slack.Blocks.Section do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  def compile(%{element: :section, attributes: %{text: text} = attrs}) do
    %{type: "section", text: Text.compile(text, attrs)}
  end
end
