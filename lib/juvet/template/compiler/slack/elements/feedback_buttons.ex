defmodule Juvet.Template.Compiler.Slack.Elements.FeedbackButtons do
  @moduledoc false

  alias Juvet.Template.Compiler.Slack.Objects.Text

  import Juvet.Template.Compiler.Encoder.Helpers, only: [maybe_put: 3]

  def compile(%{element: :feedback_buttons, attributes: attrs}) do
    %{
      type: "feedback_buttons",
      positive_button: compile_button(attrs[:positive_button]),
      negative_button: compile_button(attrs[:negative_button])
    }
    |> maybe_put(:action_id, attrs[:action_id])
  end

  defp compile_button(%{text: %{text: _} = text_attrs} = attrs) do
    %{text: Text.compile(text_attrs.text, Map.put_new(text_attrs, :type, :plain_text))}
    |> maybe_put(:value, attrs[:value])
    |> maybe_put(:accessibility_label, attrs[:accessibility_label])
  end

  defp compile_button(%{text: text} = attrs) do
    %{text: Text.compile(text, %{type: :plain_text})}
    |> maybe_put(:value, attrs[:value])
    |> maybe_put(:accessibility_label, attrs[:accessibility_label])
  end
end
