defmodule Juvet.Template.Compiler.Slack.Elements.WorkflowButton do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :workflow_button, attributes: %{text: %{text: _} = text_attrs} = attrs}) do
    %{
      type: "workflow_button",
      text: Text.compile(text_attrs.text, Map.put_new(text_attrs, :type, :plain_text))
    }
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:workflow, attrs[:workflow])
    |> maybe_put(:style, attrs[:style])
    |> maybe_put(:accessibility_label, attrs[:accessibility_label])
  end

  def compile(%{element: :workflow_button, attributes: %{text: text} = attrs}) do
    %{type: "workflow_button", text: Text.compile(text, Map.put_new(attrs, :type, :plain_text))}
    |> maybe_put(:action_id, attrs[:action_id])
    |> maybe_put(:workflow, attrs[:workflow])
    |> maybe_put(:style, attrs[:style])
    |> maybe_put(:accessibility_label, attrs[:accessibility_label])
  end
end
