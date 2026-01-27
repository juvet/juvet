defmodule Juvet.Template.Compiler.Slack.Elements.Button do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :button, attributes: %{text: text} = attrs}) do
    %{type: "button", text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))}
    |> maybe_put(:action_id, attrs[:action_id])
  end
end
